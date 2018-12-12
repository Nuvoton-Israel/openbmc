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

#include <vector>
#include <memory>
#include <signal.h>
#include <time.h>

#include "ipmbdefines.hpp"

#ifndef IPMBBRIDGED_HPP
#define IPMBBRIDGED_HPP

/**
 * @brief Ipmb addresses (8bit)
 */
constexpr uint8_t ipmbBmcSlaveAddress = 0x20;
constexpr uint8_t ipmbRqSlaveAddress = 0x58;

/**
 * @brief Ipmb outstanding requests defines
 */
constexpr int ipmbMaxOutstandingRequestsCount = 64;
constexpr int ipmbNumberOfRetries = 5;
constexpr uint64_t ipmbRequestRetryTimeout = 250; // ms

/**
 * @brief Ipmb I2C communication
 */
constexpr uint8_t ipmbI2cNumberOfRetries = 5;

/**
 * @brief Ipmb defines
 */
constexpr size_t ipmbMaxDataSize = 256;
constexpr size_t ipmbConnectionHeaderLength = 3;
constexpr size_t ipmbResponseDataHeaderLength = 4;
constexpr size_t ipmbRequestDataHeaderLength = 3;
constexpr size_t ipmbAddressSize = 1;
constexpr size_t ipmbChecksumSize = 1;
constexpr size_t ipmbChecksum2StartOffset = 3;
constexpr size_t ipmbMinFrameLength = 7;
constexpr size_t ipmbMaxFrameLength = ipmbConnectionHeaderLength +
                                      ipmbResponseDataHeaderLength +
                                      ipmbChecksumSize + ipmbMaxDataSize;

/**
 * @brief Ipmb misc
 */
constexpr uint8_t ipmbNetFnResponseMask = 0x01;
constexpr uint8_t ipmbLunMask = 0x03;
constexpr uint8_t ipmbSeqMask = 0x3F;
constexpr uint64_t ipmbOneUs = 1;

/**
 * @@:brief Ipmb misc
 */
constexpr uint8_t SMS_LUN = 0x2;

/**
 * @brief Ipmb setters
 */
constexpr uint8_t ipmbNetFnLunSet(uint8_t netFn, uint8_t lun)
{
    return ((netFn << 2) | (lun & ipmbLunMask));
}

constexpr uint8_t ipmbSeqLunSet(uint8_t seq, uint8_t lun)
{
    return ((seq << 2) | (lun & ipmbLunMask));
}

constexpr uint8_t ipmbAddressTo7BitSet(uint8_t address)
{
    return address >> 1;
}

/**
 * @brief Ipmb getters
 */
constexpr uint8_t ipmbNetFnGet(uint8_t netFnLun)
{
    return netFnLun >> 2;
}

constexpr uint8_t ipmbLunFromNetFnLunGet(uint8_t netFnLun)
{
    return netFnLun & ipmbLunMask;
}

constexpr uint8_t ipmbSeqGet(uint8_t seqNumLun)
{
    return seqNumLun >> 2;
}

constexpr uint8_t ipmbLunFromSeqLunGet(uint8_t seqNumLun)
{
    return seqNumLun & ipmbLunMask;
}

/**
 * @brief Ipmb time
 */
constexpr uint64_t ipmbMsToUs(uint64_t timeMs)
{
    return timeMs * 1000ULL;
}

constexpr uint64_t ipmbMsToNs(uint64_t timeMs)
{
    return timeMs * 1000000ULL;
}

constexpr uint64_t ipmbUsToNs(uint64_t timeUs)
{
    return timeUs * 1000ULL;
}

/**
 * @brief Ipmb checkers
 */
constexpr bool ipmbIsResponse(IPMB_HEADER *ipmbHeader)
{
    return ipmbNetFnGet(ipmbHeader->Header.Resp.rqNetFnLUN) &
           ipmbNetFnResponseMask;
}

/**
 * @brief Ipmb poll descriptors
 */
enum
{
    ipmbTimerFd = 0,
    ipmbSdBusFd,
    ipmbI2cFd,
    ipmbTotalFd
};

/**
 * @brief IpmbRequest declaration
 */
struct IpmbRequest
{
    uint8_t netFn;
    uint8_t rsLun;
    uint8_t rqSA;
    uint8_t seq;
    uint8_t rqLun;
    uint8_t cmd;
    std::vector<uint8_t> data;

    size_t dataLength;
    uint64_t timeToRetryUs;
    uint8_t retriesRemaining;

    // client data
    std::string service;
    std::string objpath;
    //@@:
    uint8_t appSeq;

    IpmbRequest();

    IpmbRequest(uint8_t netFn, uint8_t rsLun, uint8_t rqSA, uint8_t seq,
                uint8_t rqLun, uint8_t cmd, std::vector<uint8_t> &inputData,
                const char *serviceSender, const char *objpathSender,
                uint8_t appSeq);

    void updateTimeout();

    void incomingMessageHandler();

    void requestSendFailedNotify();

    void i2cToIpmbConstruct(IPMB_HEADER *ipmbBuffer, size_t bufferLength);

    size_t ipmbToi2cConstruct(std::array<uint8_t, ipmbMaxFrameLength> &buffer);

    uint64_t retryAbsTimeGet();
};

/**
 * @brief IpmbResponse declaration
 */
struct IpmbResponse
{
    uint8_t netFn;
    uint8_t rqLun;
    uint8_t rsSA;
    uint8_t seq;
    uint8_t rsLun;
    uint8_t cmd;
    uint8_t completionCode;
    std::vector<uint8_t> data;

    size_t dataLength;

    // client data
    std::string service;
    std::string objpath;
    //@@:
    uint8_t appSeq;

    IpmbResponse();

    IpmbResponse(uint8_t netFn, uint8_t rqLun, uint8_t rsSA, uint8_t seq,
                 uint8_t rsLun, uint8_t cmd, uint8_t completionCode,
                 std::vector<uint8_t> &inputData);

    void incomingMessageHandler();

    void i2cToIpmbConstruct(IPMB_HEADER *ipmbBuffer, size_t bufferLength);

    size_t ipmbToi2cConstruct(std::array<uint8_t, ipmbMaxFrameLength> &buffer);

    size_t ipmbToRMQConstruct(std::array<uint8_t, ipmbMaxFrameLength> &buffer);
};

/**
 * @brief IpmbOutstandingRequests class declaration
 */
class IpmbOutstandingRequests
{
  private:
    // list storing outstanding requests
    std::vector<std::unique_ptr<IpmbRequest>> outstandingRequests;
    // sequence number
    uint8_t seq;

    int systemTimerUpdate(uint64_t timeToRetryUs);

    void timerUpdate();

    void seqNumSet();

  public:
    int ipmbOutstandingRequestsInit();

    void requestAdd(sdbusplus::message::message &requestMessage);

    void retryRequests();

    std::unique_ptr<IpmbRequest>
        responseMatch(std::unique_ptr<IpmbResponse> &response);
};

#endif
