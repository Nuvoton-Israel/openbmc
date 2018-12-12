/* Copyright 2018 Intel
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#include <fcntl.h>
#include <inttypes.h>
#include <poll.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/timerfd.h>
//#include <linux/i2c-dev-user.h>
#include <linux/i2c-dev.h>
#include <algorithm>
#include <vector>
#include <sdbusplus/bus.hpp>
#include <sdbusplus/bus/match.hpp>
#include <sdbusplus/message.hpp>
#include <sdbusplus/vtable.hpp>
#include <sdbusplus/server/interface.hpp>
#include <phosphor-logging/log.hpp>

#include "ipmbbridged.hpp"
#include "ipmbdefines.hpp"
#include "ipmbutils.hpp"

/// @brief Ipmb outstanding requests
IpmbOutstandingRequests outstandingRequests;

/// @brief Dbus
constexpr const char *IPMB_BUS = "xyz.openbmc_project.Ipmi.Channel.Ipmb";
constexpr const char *IPMB_OBJ = "/xyz/openbmc_project/Ipmi/Channel/Ipmb";
constexpr const char *HOST_IPMI_INTF = "org.openbmc.HostIpmi";

constexpr const char *IPMB_DBUS_INTF = "org.openbmc.Ipmb";
constexpr const char *FILTER =
    "type='signal',interface='org.openbmc.Ipmb',member='sendRequest'";


sdbusplus::bus::bus bus = sdbusplus::bus::new_system();

struct pollfd ipmbi2cMasterFd;
struct pollfd ipmbFds[ipmbTotalFd];

using namespace phosphor::logging;

/**
 * @brief Ipmb request class methods
 */
IpmbRequest::IpmbRequest()
{
    data.reserve(ipmbMaxDataSize);
    dataLength = 0;
    retriesRemaining = ipmbNumberOfRetries;
}

IpmbRequest::IpmbRequest(uint8_t netFn, uint8_t rsLun, uint8_t rqSA,
                         uint8_t seq, uint8_t rqLun, uint8_t cmd,
                         std::vector<uint8_t> &inputData,
                         const char *serviceSender, const char *objpathSender,
                         uint8_t appSeq) :
    netFn(netFn),
    rsLun(rsLun), rqSA(rqSA), seq(seq), rqLun(rqLun), cmd(cmd),
    service(serviceSender), objpath(objpathSender), appSeq(appSeq)
{
    data.reserve(ipmbMaxDataSize);
    dataLength = inputData.size();
    retriesRemaining = ipmbNumberOfRetries;

    if (dataLength > 0)
    {
        data = std::move(inputData);
    }
}

void IpmbRequest::updateTimeout()
{
    uint64_t currentTime = ipmbCurrentTimeGet();
    timeToRetryUs = currentTime +
                    static_cast<uint64_t>(ipmbMsToUs(ipmbRequestRetryTimeout));
}

void IpmbRequest::incomingMessageHandler()
{
    sdbusplus::message::message mesg =
        bus.new_signal(IPMB_OBJ, HOST_IPMI_INTF, "ReceivedMessage");
    //log<level::ERR>("Sent to HOST_IPMI_INTF.ReceivedMessage");
    //@@: For rqLun is SMS_LUN, use rqLun in IpmbRequest
    //@@: It also needs to take care of rqLun & rsLun initialization in ipmbMessageSend
    //@@: when rqLun is SMS_LUN.
    mesg.append(seq, netFn, ((SMS_LUN == rqLun)? rqLun : rsLun), cmd, data);
    mesg.signal_send();
}

void IpmbRequest::i2cToIpmbConstruct(IPMB_HEADER *ipmbBuffer,
                                     size_t bufferLength)
{
    // constructing ipmb request from i2c buffer
    netFn = ipmbNetFnGet(ipmbBuffer->Header.Req.rsNetFnLUN);
    rsLun = ipmbLunFromNetFnLunGet(ipmbBuffer->Header.Req.rsNetFnLUN);
    rqSA = ipmbBuffer->Header.Req.rqSA;
    seq = ipmbSeqGet(ipmbBuffer->Header.Req.rqSeqLUN);
    rqLun = ipmbLunFromSeqLunGet(ipmbBuffer->Header.Req.rqSeqLUN);
    cmd = ipmbBuffer->Header.Req.cmd;

    dataLength =
        bufferLength - (ipmbConnectionHeaderLength +
                        ipmbRequestDataHeaderLength + ipmbChecksumSize);

    if (dataLength > 0)
    {
        data.insert(data.end(), ipmbBuffer->Header.Req.data,
                    &ipmbBuffer->Header.Req.data[dataLength]);
    }
}

size_t IpmbRequest::ipmbToi2cConstruct(
    std::array<uint8_t, ipmbMaxFrameLength> &buffer)
{
    size_t bufferLength = 0;
    static_assert(ipmbMaxFrameLength >= sizeof(IPMB_HEADER));
    auto ipmbBuffer = reinterpret_cast<IPMB_HEADER *>(buffer.data());

    // constructing buffer from ipmb request
    ipmbBuffer->Header.Req.address = ipmbRqSlaveAddress;
    ipmbBuffer->Header.Req.rsNetFnLUN = ipmbNetFnLunSet(netFn, rsLun);
    ipmbBuffer->Header.Req.rqSA = rqSA;
    ipmbBuffer->Header.Req.rqSeqLUN = ipmbSeqLunSet(seq, rqLun);
    ipmbBuffer->Header.Req.cmd = cmd;

    ipmbBuffer->Header.Resp.checksum1 = ipmbChecksumCompute(
        buffer.data(), ipmbConnectionHeaderLength - ipmbChecksumSize);

    if (dataLength > 0)
    {
        std::copy(data.begin(), data.end(), ipmbBuffer->Header.Req.data);
    }

    bufferLength =
        dataLength + ipmbRequestDataHeaderLength + ipmbConnectionHeaderLength;

    buffer[bufferLength] =
        ipmbChecksumCompute(&buffer[ipmbChecksum2StartOffset],
                            (ipmbRequestDataHeaderLength + dataLength));

    bufferLength += ipmbChecksumSize;

    return bufferLength;
}

uint64_t IpmbRequest::retryAbsTimeGet()
{
    return timeToRetryUs;
}

void IpmbRequest::requestSendFailedNotify()
{
    sdbusplus::message::message mesg = bus.new_method_call(
        service.c_str(), objpath.c_str(), IPMB_DBUS_INTF, "requestSendFailed");

    mesg.append(appSeq, netFn, rqLun, cmd, data);
    sdbusplus::message::message resp = bus.call(mesg);

    if (resp.is_method_error())
    {
        log<level::ERR>("method error: sending requestSendFailedNotify");
    }
}

/**
 * @brief Ipmb response class methods
 */
IpmbResponse::IpmbResponse()
{
    data.reserve(ipmbMaxDataSize);
    dataLength = 0;
}

IpmbResponse::IpmbResponse(uint8_t netFn, uint8_t rqLun, uint8_t rsSA,
                           uint8_t seq, uint8_t rsLun, uint8_t cmd,
                           uint8_t completionCode,
                           std::vector<uint8_t> &inputData) :
    netFn(netFn),
    rqLun(rqLun), rsSA(rsSA), seq(seq), rsLun(rsLun), cmd(cmd),
    completionCode(completionCode)
{
    data.reserve(ipmbMaxDataSize);
    dataLength = inputData.size();

    if (dataLength > 0)
    {
        data = std::move(inputData);
    }
}

void IpmbResponse::incomingMessageHandler()
{
    //@@: treat rqLun 0x2 as sending the response to RMQ
    //sdbusplus::message::message mesg = bus.new_method_call(
    //        "xyz.openbmc_project.Control.Host", "/org/openbmc/HostIpmi", "org.openbmc.Ipmb", (SMS_LUN != rqLun) ? "returnResponse" : "returnRawResponse");
    sdbusplus::message::message mesg = bus.new_method_call(
              service.c_str(), objpath.c_str(), IPMB_DBUS_INTF, (SMS_LUN != rqLun) ? "returnResponse" : "returnRawResponse");
    std::array<uint8_t, ipmbMaxFrameLength> buffer{};

    if(SMS_LUN != rqLun)
    {
        mesg.append(appSeq, netFn, rsLun, cmd, completionCode, data);
    }
    else
    {
        std::vector<uint8_t> dataReceived;
        dataReceived.reserve(ipmbMaxFrameLength);
        size_t msg_size = ipmbToRMQConstruct(buffer);
        dataReceived.insert(dataReceived.end(), &buffer[0],
                    &buffer[msg_size]);

        mesg.append(dataReceived);
    }

    sdbusplus::message::message resp = bus.call(mesg);

    if (resp.is_method_error())
    {
        log<level::ERR>("method error: sending response to the client app");
    }
}

void IpmbResponse::i2cToIpmbConstruct(IPMB_HEADER *ipmbBuffer,
                                      size_t bufferLength)
{
    netFn = ipmbNetFnGet(ipmbBuffer->Header.Resp.rqNetFnLUN);
    rqLun = ipmbLunFromNetFnLunGet(ipmbBuffer->Header.Resp.rqNetFnLUN);
    rsSA = ipmbBuffer->Header.Resp.rsSA;
    seq = ipmbSeqGet(ipmbBuffer->Header.Resp.rsSeqLUN);
    rsLun = ipmbLunFromSeqLunGet(ipmbBuffer->Header.Resp.rsSeqLUN);
    cmd = ipmbBuffer->Header.Resp.cmd;
    completionCode = ipmbBuffer->Header.Resp.completionCode;

    dataLength =
        bufferLength - (ipmbConnectionHeaderLength +
                        ipmbResponseDataHeaderLength + ipmbChecksumSize);

    if (dataLength > 0)
    {
        data.insert(data.end(), ipmbBuffer->Header.Resp.data,
                    &ipmbBuffer->Header.Resp.data[dataLength]);
    }
}

size_t IpmbResponse::ipmbToi2cConstruct(
    std::array<uint8_t, ipmbMaxFrameLength> &buffer)
{
    size_t bufferLength = 0;
    auto ipmbBuffer = reinterpret_cast<IPMB_HEADER *>(buffer.data());

    ipmbBuffer->Header.Resp.address = ipmbRqSlaveAddress;
    ipmbBuffer->Header.Resp.rqNetFnLUN = ipmbNetFnLunSet(netFn, rqLun);
    ipmbBuffer->Header.Resp.rsSA = rsSA;
    ipmbBuffer->Header.Resp.rsSeqLUN = ipmbSeqLunSet(seq, rsLun);
    ipmbBuffer->Header.Resp.cmd = cmd;
    ipmbBuffer->Header.Resp.completionCode = completionCode;

    ipmbBuffer->Header.Resp.checksum1 = ipmbChecksumCompute(
        buffer.data(), ipmbConnectionHeaderLength - ipmbChecksumSize);

    if (dataLength > 0)
    {
        std::copy(data.begin(), data.end(), ipmbBuffer->Header.Resp.data);
    }

    bufferLength =
        dataLength + ipmbResponseDataHeaderLength + ipmbConnectionHeaderLength;

    buffer[bufferLength] =
        ipmbChecksumCompute(&buffer[ipmbChecksum2StartOffset],
                            (ipmbResponseDataHeaderLength + dataLength));

    bufferLength += ipmbChecksumSize;

    return bufferLength;
}

size_t IpmbResponse::ipmbToRMQConstruct(
    std::array<uint8_t, ipmbMaxFrameLength> &buffer)
{
    size_t bufferLength = 0;
    auto ipmbBuffer = reinterpret_cast<IPMB_HEADER *>(buffer.data());
    //@@: According to IPMI spec. 7-3 & 7-4, the rqSA would be the BMC addr 0x20.
    //@@: Also, the rsSA address would be the slave dev addr.
    ipmbBuffer->Header.Resp.address = ipmbBmcSlaveAddress;
    ipmbBuffer->Header.Resp.rqNetFnLUN = ipmbNetFnLunSet(netFn, rqLun);
    ipmbBuffer->Header.Resp.rsSA = ipmbRqSlaveAddress;
    ipmbBuffer->Header.Resp.rsSeqLUN = ipmbSeqLunSet(seq, rsLun);
    ipmbBuffer->Header.Resp.cmd = cmd;
    ipmbBuffer->Header.Resp.completionCode = completionCode;

    ipmbBuffer->Header.Resp.checksum1 = ipmbChecksumCompute(
        buffer.data(), ipmbConnectionHeaderLength - ipmbChecksumSize);

    if (dataLength > 0)
    {
        std::copy(data.begin(), data.end(), ipmbBuffer->Header.Resp.data);
    }

    bufferLength =
        dataLength + ipmbResponseDataHeaderLength + ipmbConnectionHeaderLength;

    buffer[bufferLength] =
        ipmbChecksumCompute(&buffer[ipmbChecksum2StartOffset],
                            (ipmbResponseDataHeaderLength + dataLength));

    bufferLength += ipmbChecksumSize;

    return bufferLength;
}

/**
 * @brief Ipmb channel
 */
static int ipmbSend(std::array<uint8_t, ipmbMaxFrameLength> &buffer,
                    size_t bufferSize)
{
    // retries handle rare situations of hw being unable to perform transaction.
    // number of retries is arbitrarly set value
    for (int sendCount = 0; sendCount < ipmbI2cNumberOfRetries; sendCount++)
    {
        if (write(ipmbi2cMasterFd.fd, &buffer[ipmbAddressSize],
                  (bufferSize - ipmbAddressSize)) ==
            (bufferSize - ipmbAddressSize))
        {
            return 0;
        }
    }

    log<level::ERR>("Sent to I2C failed after retries");

    return -1;
}

/**
 * @brief Ipmb Outstanding Requests
 */
int IpmbOutstandingRequests::ipmbOutstandingRequestsInit()
{
    seq = 0;
    ipmbFds[ipmbTimerFd].fd = timerfd_create(CLOCK_MONOTONIC, 0);

    if (ipmbFds[ipmbTimerFd].fd < 0)
    {
        return -1;
    }

    return 0;
}

void IpmbOutstandingRequests::requestAdd(
    sdbusplus::message::message &requestMessage)
{
    size_t bufferLength = 0;
    uint8_t appSeq = 0;
    uint8_t netfn = 0, lun = 0, cmd = 0;
    std::array<uint8_t, ipmbMaxFrameLength> buffer{};
    std::vector<uint8_t> dataReceived;

    dataReceived.reserve(ipmbMaxDataSize);

    requestMessage.read(appSeq, netfn, lun, cmd, dataReceived);

    if (dataReceived.size() > ipmbMaxDataSize)
    {
        return;
    }

    //@@: If lun is SMS_LUN, it stands for a bridging message from SI to IPMB.
    //@@: Configure rsLun to be 0x0 since rsLun in IPMB response is 0x0 in such a case.
    std::unique_ptr<IpmbRequest> ipmbMessageReceived =
        std::make_unique<IpmbRequest>(
            netfn, ((SMS_LUN == lun)? 0 : lun), ipmbBmcSlaveAddress, seq, lun, cmd, dataReceived,
            requestMessage.get_sender(), requestMessage.get_path(), appSeq);

    // check if we can add another request to the list
    if (outstandingRequests.size() == ipmbMaxOutstandingRequestsCount)
    {
        log<level::DEBUG>("cannot add more requests to the list");
        ipmbMessageReceived->requestSendFailedNotify();
        return;
    }

    // send the request, update the time of next retry, add to the list and bump
    // up sequence number
    bufferLength = ipmbMessageReceived->ipmbToi2cConstruct(buffer);
    static_cast<void>(ipmbSend(buffer, bufferLength));
    ipmbMessageReceived->updateTimeout();
    outstandingRequests.push_back(std::move(ipmbMessageReceived));
    timerUpdate();
    seqNumSet();
}

int IpmbOutstandingRequests::systemTimerUpdate(uint64_t timeToRetryUs)
{
    struct itimerspec iTimerpec;
    iTimerpec.it_interval.tv_sec = 0;
    iTimerpec.it_interval.tv_nsec = 0;
    iTimerpec.it_value.tv_sec = 0;
    iTimerpec.it_value.tv_nsec = ipmbUsToNs(timeToRetryUs);

    if (timerfd_settime(ipmbFds[ipmbTimerFd].fd, 0, &iTimerpec, nullptr) == -1)
    {
        log<level::ERR>("timerfd_settime() error");
        return -1;
    }

    return 0;
}

void IpmbOutstandingRequests::timerUpdate()
{
    uint64_t timeToRetryUs = 0;

    // sort the list by the expiration time
    std::sort(outstandingRequests.begin(), outstandingRequests.end(),
              [](const std::unique_ptr<IpmbRequest> &requestFirst,
                 const std::unique_ptr<IpmbRequest> &requestSecond) -> bool {
                  return (requestFirst->retryAbsTimeGet() <
                          requestSecond->retryAbsTimeGet());
              });

    // disable timer
    systemTimerUpdate(0);

    uint64_t currentTime = ipmbCurrentTimeGet();

    auto request = outstandingRequests.begin();
    if (request == outstandingRequests.end())
    {
        // list empty, no need to set the timer
        return;
    }
    else
    {
        // next Expiration Time in the past
        if (currentTime >= (*request)->timeToRetryUs)
        {
            // set timer for 1 ms so it expires immediately
            timeToRetryUs = ipmbOneUs;
        }
        else
        {
            // set timer to the neares expiration time
            timeToRetryUs = (*request)->timeToRetryUs - currentTime;
        }
    }

    systemTimerUpdate(timeToRetryUs);
}

void IpmbOutstandingRequests::retryRequests()
{
    std::array<uint8_t, ipmbMaxFrameLength> buffer{};
    size_t dataLength = 0;

    uint64_t currentTime = ipmbCurrentTimeGet();

    auto request = outstandingRequests.begin();
    while (request != outstandingRequests.end())
    {
        // request timed out (no retries left). Erase it
        if ((*request)->retriesRemaining == 0)
        {
            (*request)->requestSendFailedNotify();
            request = outstandingRequests.erase(request);
            continue;
        }
        else
        {
            // Check if request should be retried now
            if ((*request)->timeToRetryUs <= currentTime)
            {
                dataLength = (*request)->ipmbToi2cConstruct(buffer);
                static_cast<void>(ipmbSend(buffer, dataLength));
                (*request)->retriesRemaining--;
                (*request)->updateTimeout();
            }
            // If current request timeToRetryUs is not in the past, we can leave
            else
            {
                break;
            }
        }
        request++;
    }

    timerUpdate();
}

void IpmbOutstandingRequests::seqNumSet()
{
    seq = ++seq & ipmbSeqMask;
}

std::unique_ptr<IpmbRequest> IpmbOutstandingRequests::responseMatch(
    std::unique_ptr<IpmbResponse> &response)
{
    for (auto request = outstandingRequests.begin();
         request != outstandingRequests.end(); ++request)
    {
        if ((((*request)->netFn |= 1) == (response->netFn)) &&
            (((*request)->rqLun) == (response->rqLun)) &&
            (((*request)->rsLun) == (response->rsLun)) &&
            (((*request)->seq) == (response->seq)) &&
            (((*request)->cmd) == (response->cmd)))
        {
            // match, response is corresponding to previously sent request
            // copy relevant client data
            response->service = std::move((*request)->service);
            response->objpath = std::move((*request)->objpath);
            response->appSeq = (*request)->appSeq;

            auto matchedRequest = std::move(*request);
            outstandingRequests.erase(request);
            timerUpdate();

            return matchedRequest;
        }
    }

    // no match, return null pointer
    return nullptr;
}

/**
 * @brief Dbus methods
 */
static int ipmbSignalCallback(sd_bus_message *bus_msg, void *userdata,
                              sd_bus_error *ret_error)
{
    auto mesg = sdbusplus::message::message(bus_msg);
    outstandingRequests.requestAdd(mesg);

    return 1;
}

static int ipmbMessageSend(sd_bus_message *bus_msg, void *userdata,
                           sd_bus_error *ret_error)
{
    int64_t status = -1;
    size_t bufferLength = 0;
    uint8_t netfn = 0, lun = 0, seq = 0, cmd = 0, cc = 0;
    std::array<uint8_t, ipmbMaxFrameLength> buffer{};
    std::vector<uint8_t> dataReceived;

    dataReceived.reserve(ipmbMaxDataSize);
    auto mesg = sdbusplus::message::message(bus_msg);

    do
    {
        mesg.read(seq, netfn, lun, cmd, cc, dataReceived);
        if (dataReceived.size() > ipmbMaxDataSize)
        {
            status = -1;
            break;
        }

        if (netfn & ipmbNetFnResponseMask)
        {
            // response received
            // dataReceived is empty after constructor invocation
            //@@: For lun is SMS_LUN, rsLun is 0 in ipmb message bridging case.
            //@@: Otherwise, use the original lun value.
            std::unique_ptr<IpmbResponse> ipmbMessageReceived =
                std::make_unique<IpmbResponse>(netfn, lun, ipmbBmcSlaveAddress,
                                               seq, ((SMS_LUN == lun)? 0 : lun), cmd, cc, dataReceived);

            bufferLength = ipmbMessageReceived->ipmbToi2cConstruct(buffer);
            log<level::ERR>("Receiving a IPMB response");
            status = ipmbSend(buffer, bufferLength);
        }
        else
        {
            // we are not expecting request here
            log<level::ERR>("ipmbMessageSend got a request");
            status = -1;
        }
    } while (0);

    sdbusplus::message::message reply = mesg.new_method_return();
    reply.append(status);
    reply.method_return();

    return 1;
}

static const sdbusplus::vtable::vtable_t ipmiVtable[] = {
    sdbusplus::vtable::start(),
    sdbusplus::vtable::method("sendMessage", "yyyyyay", "x", ipmbMessageSend),
    sdbusplus::vtable::signal("ReceivedMessage", "yyyyay"),
    sdbusplus::vtable::end()};

/**
 * @brief Main
 */
int main(int argc, char *argv[])
{
    int r = -1;
    std::array<uint8_t, ipmbMaxFrameLength> buffer{};

    const char *ipmbI2cSlave = "/sys/bus/i2c/devices/4-1010/slave-mqueue";
    const char *ipmbI2cMaster = "/dev/i2c-4";

    sdbusplus::server::interface::interface ipmiInterface(
        bus, IPMB_OBJ, HOST_IPMI_INTF, ipmiVtable, nullptr);

    sdbusplus::bus::match::match match(bus, FILTER, ipmbSignalCallback);

    bus.request_name(IPMB_BUS);

    ipmbFds[ipmbSdBusFd].fd = bus.get_fd();
    if (ipmbFds[ipmbSdBusFd].fd < 0)
    {
        log<level::ERR>("Error getting fd from bus object");
        return -1;
    }

    // open fd to i2c slave device
    ipmbFds[ipmbI2cFd].fd =
        open(ipmbI2cSlave, O_RDONLY | O_NONBLOCK | O_CLOEXEC);
    if (ipmbFds[ipmbI2cFd].fd < 0)
    {
        log<level::ERR>("Error opening ipmbI2cSlave");
        return -1;
    }

    // open fd to i2c master device
    ipmbi2cMasterFd.fd = open(ipmbI2cMaster, O_RDWR | O_NONBLOCK);
    if (ipmbi2cMasterFd.fd < 0)
    {
        log<level::ERR>("Error opening ipmbI2cMaster");
        return -1;
    }

    // set slave address of recipient
    if (ioctl(ipmbi2cMasterFd.fd, I2C_SLAVE,
              ipmbAddressTo7BitSet(ipmbRqSlaveAddress)) < 0)
    {
        log<level::ERR>("Error setting ipmbi2cMasterFd slave address");
        return -1;
    }

    // initialize outstanding requests module
    if (outstandingRequests.ipmbOutstandingRequestsInit() < 0)
    {
        log<level::ERR>("Error ipmbOutstandingRequestsInit()");
        return -1;
    }

    // set proper events to poll for
    ipmbFds[ipmbSdBusFd].events = POLLIN;
    ipmbFds[ipmbI2cFd].events = POLLPRI;
    ipmbFds[ipmbTimerFd].events = POLLIN;

    while (1)
    {
        r = poll(ipmbFds, ipmbTotalFd, -1);

        if (r < 0)
        {
            continue;
        }

        // outstanding requests timer expired
        if (ipmbFds[ipmbTimerFd].revents & POLLIN)
        {
            outstandingRequests.retryRequests();
        }

        // received dbus event
        if (ipmbFds[ipmbSdBusFd].revents & POLLIN)
        {
            bus.process_discard();
        }

        // received i2c slave event
        if (ipmbFds[ipmbI2cFd].revents & POLLPRI)
        {
            if (r == 0)
                continue;

            lseek(ipmbFds[ipmbI2cFd].fd, 0, SEEK_SET);
            r = read(ipmbFds[ipmbI2cFd].fd, buffer.data(), ipmbMaxFrameLength);
            if ((r < ipmbMinFrameLength) || (r > ipmbMaxFrameLength))
                continue;

            auto ipmbFrame = reinterpret_cast<IPMB_HEADER *>(buffer.data());

            // valiate the frame
            if (!isFrameValid(ipmbFrame, r))
            {
                continue;
            }

            // copy frame to ipmib message buffer
            if (ipmbIsResponse(ipmbFrame))
            {
                std::unique_ptr<IpmbResponse> ipmbMessageReceived =
                    std::make_unique<IpmbResponse>();

                ipmbMessageReceived->i2cToIpmbConstruct(ipmbFrame, r);

                // lets match response with outstanding request
                auto ipmbMessageOutstanding =
                    outstandingRequests.responseMatch(ipmbMessageReceived);
                if (ipmbMessageOutstanding)
                {
                    // matching request found - send response to the client
                    ipmbMessageReceived->incomingMessageHandler();
                }

                // no match - discard the message and proceed
            }
            else
            {
                std::unique_ptr<IpmbRequest> ipmbMessageReceived =
                    std::make_unique<IpmbRequest>();

                ipmbMessageReceived->i2cToIpmbConstruct(ipmbFrame, r);

                // send request to the client
                ipmbMessageReceived->incomingMessageHandler();
            }
        }
    }

    close(ipmbFds[ipmbI2cFd].fd);
    close(ipmbFds[ipmbTimerFd].fd);
    close(ipmbi2cMasterFd.fd);

    return 0;
}
