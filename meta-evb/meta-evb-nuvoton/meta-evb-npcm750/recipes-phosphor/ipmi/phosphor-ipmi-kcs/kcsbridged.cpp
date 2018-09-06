/* Copyright 2017 Intel
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

#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <limits.h>
#include <poll.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/timerfd.h>
#include <time.h>
#include <unistd.h>

#include <linux/ipmi_bmc.h>

#include <sdbusplus/vtable.hpp>

#define KCS_MAX_MESSAGE 256

const char * KCS_IPMI_BUS = "xyz.openbmc_project.Ipmi.Channel.Sms";
const char * KCS_IPMI_OBJ = "/xyz/openbmc_project/Ipmi/Channel/Sms";
const char * HOST_IPMI_INTF = "org.openbmc.HostIpmi";

const char * kcs_bmc_device = "/dev/ipmi-kcs3";

struct ipmi_msg
{
    uint8_t  netfn;
    uint8_t  lun;
    uint8_t  cmd;
    uint8_t  cc; /* Only used on responses */
    uint8_t *data;
    size_t   data_len;
};

struct kcs_msg_entry
{
    uint8_t          seq;

    struct ipmi_msg  req;
    struct ipmi_msg  rsp;
};

enum
{
    SD_BUS_FD = 0,
    KCS_FD,
    TOTAL_FDS
};

struct kcsbridged_context
{
    struct pollfd  fds[TOTAL_FDS];
    struct sd_bus *bus;

    struct kcs_msg_entry  kcs_msg;
};

static enum
{
    KCS_LOG_NONE = 0,
    KCS_LOG_VERBOSE,
    KCS_LOG_DEBUG
} log_verbosity = KCS_LOG_NONE;

__attribute__((format(printf, 1, 2)))
static void kcs_log(const char *fmt, ...)
{
    if (log_verbosity != KCS_LOG_NONE)
    {
        va_list args;

        va_start(args, fmt);
        vfprintf(stderr, fmt, args);
        va_end(args);
    }
}

static void kcs_print_message(uint8_t *data, size_t data_len)
{
    size_t i;
    int str_len;
    char str[64];

    str_len = 0;
    for (i = 0; i < data_len; i++)
    {
        if (i % 8 == 0)
        {
            if (i != 0)
            {
                kcs_log("%s\n", str);
                str_len = 0;
             }
             str_len += sprintf(&str[str_len], "\t");
        }

        str_len += sprintf(&str[str_len], "0x%02x ", data[i]);
    }

    if (str_len != 0)
    {
        kcs_log("%s\n", str);
    }
}

static struct kcs_msg_entry *handle_kcs_request(struct kcsbridged_context *context, uint8_t *req, size_t len)
{
    struct kcs_msg_entry *kcs_msg = &context->kcs_msg;

    if (len < 2)
    {
        kcs_log("KCS message with a short length (%d)\n", len);
        return NULL;
    }

    kcs_msg->seq++;

    kcs_msg->req.netfn = req[0] >> 2;
    kcs_msg->req.lun = req[0] & 0x3;
    kcs_msg->req.cmd = req[1];
    kcs_msg->req.data = req + 2;
    kcs_msg->req.data_len = len - 2;

    return kcs_msg;
}

static int handle_kcs_response(struct kcsbridged_context *context, struct kcs_msg_entry *kcs_msg)
{
    int r;
    uint8_t data[KCS_MAX_MESSAGE];

    if (!kcs_msg)
    {
        return -EINVAL;
    }

    data[0] = (kcs_msg->rsp.netfn << 2) | (kcs_msg->rsp.lun & 0x3);
    data[1] = kcs_msg->rsp.cmd;
    data[2] = kcs_msg->rsp.cc;
    if (kcs_msg->rsp.data_len > sizeof(data) - 3) {
        kcs_log("Response message size (%zu) too big, truncating\n", kcs_msg->rsp.data_len);
        kcs_msg->rsp.data_len = sizeof(data) - 3;
    }
    if (kcs_msg->rsp.data_len)
    {
        memcpy(data + 3, kcs_msg->rsp.data, kcs_msg->rsp.data_len);
    }

    r = write(context->fds[KCS_FD].fd, data, kcs_msg->rsp.data_len + 3);
    if (r > 0)
    {
        r = 0;
    }

    return r;
}

static int method_send_sms_atn(sd_bus_message *bus_msg, void *userdata, sd_bus_error *ret_error)
{
    int r;
    uint8_t set;
    struct kcsbridged_context *context;

    context = reinterpret_cast<struct kcsbridged_context *> (userdata);
    if (!context)
    {
        return sd_bus_reply_method_errno(bus_msg, -EINVAL, ret_error);
    }

    r = sd_bus_message_read(bus_msg, "y", &set);
    if (r < 0)
    {
        kcs_log("Couldn't parse leading bytes of message: %s\n", strerror(-r));
        return sd_bus_reply_method_errno(bus_msg, errno, ret_error);
    }

    kcs_log("Sending %s_SMS_ATN ioctl to %s\n", set != 0 ? "SET" : "CLEAR", kcs_bmc_device);

    r = ioctl(context->fds[KCS_FD].fd, set != 0 ? IPMI_BMC_IOCTL_SET_SMS_ATN : IPMI_BMC_IOCTL_CLEAR_SMS_ATN);
    if (r == -1)
    {
        r = errno;
        kcs_log("Failed SMS_ATN %s: %s\n", kcs_bmc_device, strerror(r));
        return sd_bus_reply_method_errno(bus_msg, errno, ret_error);
    }

    r = 0;
    return sd_bus_reply_method_return(bus_msg, "x", r);
}

static int method_send_message(sd_bus_message *bus_msg, void *userdata, sd_bus_error *ret_error)
{
    struct kcsbridged_context *context;
    struct kcs_msg_entry *kcs_msg;
    uint8_t *data;
    size_t data_sz;
    uint8_t netfn, lun, seq, cmd, cc;
    /*
     * Doesn't say it anywhere explicitly but it looks like returning 0 or
     * negative is BAD...
     */
    int r = 1;

    context = reinterpret_cast<struct kcsbridged_context *> (userdata);
    if (!context)
    {
        r = 0;
        sd_bus_error_set_const(ret_error, "org.openbmc.error", "Internal error");
        goto out;
    }

    r = sd_bus_message_read(bus_msg, "yyyyy", &seq, &netfn, &lun, &cmd, &cc);
    if (r < 0)
    {
        kcs_log("Couldn't parse leading bytes of message: %s\n", strerror(-r));
        sd_bus_error_set_const(ret_error, "org.openbmc.error", "Bad message");
        r = -EINVAL;
        goto out;
    }

    r = sd_bus_message_read_array(bus_msg, 'y', (const void **)&data, &data_sz);
    if (r < 0)
    {
        kcs_log("Couldn't parse data bytes of message: %s\n", strerror(-r));
        sd_bus_error_set_const(ret_error, "org.openbmc.error", "Bad message data");
        r = -EINVAL;
        goto out;
    }

    kcs_msg = &context->kcs_msg;
    if (kcs_msg->seq != seq)
    {
        sd_bus_error_set_const(ret_error, "org.openbmc.error", "No matching request");
        kcs_log("Failed to find matching request for dbus method with seq: 0x%02x\n", seq);
        r = -EINVAL;
        goto out;
    }

    kcs_msg->rsp.netfn = netfn;
    kcs_msg->rsp.lun = lun;
    kcs_msg->rsp.cmd = cmd;
    kcs_msg->rsp.cc = cc;
    kcs_msg->rsp.data = data;
    kcs_msg->rsp.data_len = data_sz;

    kcs_log("Send rsp msg <- seq=0x%02x netfn=0x%02x lun=0x%02x cmd=0x%02x cc=0x%02x\n",
            kcs_msg->seq,
            kcs_msg->rsp.netfn,
            kcs_msg->rsp.lun,
            kcs_msg->rsp.cmd,
            kcs_msg->rsp.cc);

    if (log_verbosity == KCS_LOG_DEBUG)
    {
        kcs_print_message(kcs_msg->rsp.data, kcs_msg->rsp.data_len);
    }

    r = handle_kcs_response(context, kcs_msg);

out:
    return sd_bus_reply_method_return(bus_msg, "x", r);
}

static int dispatch_sd_bus(struct kcsbridged_context *context)
{
    int r = 0;

    if (context->fds[SD_BUS_FD].revents)
    {
        r = sd_bus_process(context->bus, NULL);
        if (r > 0)
        {
            kcs_log("Processed %d dbus events\n", r);
        }
    }

    return r;
}

static int dispatch_kcs(struct kcsbridged_context *context)
{
    int r = 0;
    int err = 0;
    struct kcs_msg_entry *kcs_msg;
    sd_bus_message       *bus_msg;
    uint8_t data[KCS_MAX_MESSAGE];

    if (!(context->fds[KCS_FD].revents & POLLIN))
    {
        goto out;
    }

    r = read(context->fds[KCS_FD].fd, data, sizeof(data));
    if (r < 0)
    {
        kcs_log("Couldn't read from KCS: %s\n", strerror(-r));
        goto out;
    }

    kcs_msg = handle_kcs_request(context, data, r);
    if (kcs_msg == NULL)
    {
        kcs_log("Failed to handle KCS message on %s\n", kcs_bmc_device);
        err = -EIO;
        goto out;
    }

    r = sd_bus_message_new_signal(context->bus, &bus_msg, KCS_IPMI_OBJ,
                HOST_IPMI_INTF, "ReceivedMessage");
    if (r < 0)
    {
        kcs_log("Failed to create signal: %s\n", strerror(-r));
        goto out;
    }

    r = sd_bus_message_append(bus_msg, "yyyy",
                kcs_msg->seq,
                kcs_msg->req.netfn,
                kcs_msg->req.lun,
                kcs_msg->req.cmd);
    if (r < 0)
    {
        kcs_log("Couldn't append header to signal: %s\n", strerror(-r));
        goto free;
    }

    r = sd_bus_message_append_array(bus_msg, 'y', kcs_msg->req.data, kcs_msg->req.data_len);
    if (r < 0)
    {
        kcs_log("Couldn't append array to signal: %s\n", strerror(-r));
        goto free;
    }

    kcs_log("Recv req msg -> seq=0x%02x netfn=0x%02x lun=0x%02x cmd=0x%02x\n",
            kcs_msg->seq,
            kcs_msg->req.netfn,
            kcs_msg->req.lun,
            kcs_msg->req.cmd);

    if (log_verbosity == KCS_LOG_DEBUG)
    {
        kcs_print_message(kcs_msg->req.data, kcs_msg->req.data_len);
    }

    r = sd_bus_send(context->bus, bus_msg, NULL);
    if (r < 0)
    {
        kcs_log("Couldn't emit dbus signal: %s\n", strerror(-r));
    }

free:
    sd_bus_message_unref(bus_msg);
out:
    return err ? err : r;
}

static void usage(const char *name)
{
    fprintf(stderr,
        "Usage %s [--v[v]] [-d <DEVICE>]\n"
        "--v                    Be verbose\n"
        "--vv                   Be verbose and dump entire messages\n"
        "-d, --device <DEVICE>  use <DEVICE> file. Default is '%s'\n\n",
        name, kcs_bmc_device);
}

static const sdbusplus::vtable::vtable_t kcs_ipmi_vtable[] =
    {
        sdbusplus::vtable::start(),
        sdbusplus::vtable::method("sendMessage", "yyyyyay", "x", method_send_message),
        sdbusplus::vtable::method("setAttention", "y", "x", method_send_sms_atn),
        sdbusplus::vtable::signal("ReceivedMessage", "yyyyay"),
        sdbusplus::vtable::end()
    };

int main(int argc, char *argv[])
{
    const char *name = argv[0];
    int opt, polled, r;
    struct kcsbridged_context *context;

    static const struct option long_options[] =
        {
            { "device",  required_argument, NULL, 'd' },
            { "v",       no_argument, (int *)&log_verbosity, KCS_LOG_VERBOSE },
            { "vv",      no_argument, (int *)&log_verbosity, KCS_LOG_DEBUG   },
            { 0,         0,           0,          0           }
        };

    context = reinterpret_cast<struct kcsbridged_context *> (calloc(1, sizeof(*context)));
    if (context == NULL)
    {
        printf("Failed to alloc kcsbridged context!\n");
        return -1;
    }

    while ((opt = getopt_long(argc, argv, "", long_options, NULL)) != -1)
    {
        switch (opt)
        {
            case 0:
                break;

            case 'd':
                kcs_bmc_device = optarg;
                break;

            default:
                usage(name);
                exit(EXIT_FAILURE);
        }
    }

    if (log_verbosity == KCS_LOG_VERBOSE)
    {
        kcs_log("Verbose logging\n");
    }
    else if (log_verbosity == KCS_LOG_DEBUG)
    {
        kcs_log("Debug logging\n");
    }

    kcs_log("Starting\n");

    r = sd_bus_default_system(&context->bus);
    if (r < 0)
    {
        kcs_log("Failed to connect to system bus: %s\n", strerror(-r));
        goto finish;
    }

    r = sd_bus_add_object_vtable(context->bus,
                NULL,
                KCS_IPMI_OBJ,
                HOST_IPMI_INTF,
                kcs_ipmi_vtable,
                context);
    if (r < 0)
    {
        kcs_log("Failed to issue method call: %s\n", strerror(-r));
        goto finish;
    }

    r = sd_bus_request_name(context->bus, KCS_IPMI_BUS, SD_BUS_NAME_ALLOW_REPLACEMENT | SD_BUS_NAME_REPLACE_EXISTING);
    if (r < 0)
    {
        kcs_log("Failed to acquire service name: %s\n", strerror(-r));
        goto finish;
    }

    context->fds[SD_BUS_FD].fd = sd_bus_get_fd(context->bus);
    if (context->fds[SD_BUS_FD].fd < 0)
    {
        r = -errno;
        kcs_log("Couldn't get the bus file descriptor: %s\n", strerror(errno));
        goto finish;
    }

    context->fds[KCS_FD].fd = open(kcs_bmc_device, O_RDWR | O_NONBLOCK | O_CLOEXEC);
    if (context->fds[KCS_FD].fd < 0)
    {
        r = -errno;
        kcs_log("Couldn't open %s with flags O_RDWR: %s\n", kcs_bmc_device, strerror(errno));
        goto finish;
    }

    r = ioctl(context->fds[KCS_FD].fd, IPMI_BMC_IOCTL_FORCE_ABORT);
    if (r == -1)
    {
        r = errno;
        kcs_log("Couldn't ioctl() to 0x%x, %s: %s\n", context->fds[KCS_FD].fd, kcs_bmc_device, strerror(r));
    }

    context->fds[SD_BUS_FD].events = POLLIN;
    context->fds[KCS_FD].events = POLLIN;

    kcs_log("Entering polling loop\n");

    while (1)
    {
        polled = poll(context->fds, TOTAL_FDS, 5000);

        if (polled == 0)
        {
            continue;
        }

        if (polled < 0)
        {
            r = -errno;
            kcs_log("Error from poll(): %s\n", strerror(errno));
            break;
        }

        r = dispatch_sd_bus(context);
        if (r < 0)
        {
            kcs_log("Error handling dbus event: %s\n", strerror(-r));
            break;
        }

        r = dispatch_kcs(context);
        if (r < 0)
        {
            kcs_log("Error handling KCS event: %s\n", strerror(-r));
            break;
        }
    }

finish:
    close(context->fds[KCS_FD].fd);
    sd_bus_unref(context->bus);
    free(context);

    return r;
}

