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
#include <stdio.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>
#include <phosphor-logging/log.hpp>

#include "ipmbbridged.hpp"
#include "ipmbdefines.hpp"

using namespace phosphor::logging;

/**
 * @brief Current time getter
 */
uint64_t ipmbCurrentTimeGet()
{
    struct timespec timespec = {0};
    int ret = -1;

    ret = clock_gettime(CLOCK_MONOTONIC, &timespec);
    if (ret == 0)
    {
        return (timespec.tv_sec * 1000000ULL) + (timespec.tv_nsec / 1000ULL);
    }

    log<level::ERR>("clock_gettime() error");
    return 0;
}

/**
 * @brief Ipmb utils for checksum
 */
bool ipmbChecksumValidate(uint8_t *data, uint8_t length)
{
    uint8_t checksum = 0;

    // compute checksum.
    for (uint8_t idx = 0; idx < length; idx++)
    {
        checksum += data[idx];
    }

    // check if checksum is valid.
    if (0 == checksum)
    {
        // checksum valid.
        return true;
    }
    else
    {
        // checksum invalid.
        return false;
    }
}

uint8_t ipmbChecksumCompute(uint8_t *data, uint8_t length)
{
    uint8_t checksum = 0;

    // compute checksum.
    for (uint8_t idx = 0; idx < length; idx++)
    {
        checksum += data[idx];
    }

    checksum = (~checksum) + 1;

    // return computed checksum value.
    return checksum;
}

inline bool ipmbConnectionHeaderChecksumValidate(IPMB_HEADER *ipmbHeader)
{
    return ipmbChecksumValidate(reinterpret_cast<uint8_t *>(ipmbHeader),
                                ipmbConnectionHeaderLength);
}

inline bool ipmbDataChecksumValidate(IPMB_HEADER *ipmbHeader, uint8_t length)
{
    return ipmbChecksumValidate(
        (reinterpret_cast<uint8_t *>(ipmbHeader) + ipmbConnectionHeaderLength),
        (length - ipmbConnectionHeaderLength));
}

bool isFrameValid(IPMB_HEADER *frame, uint8_t length)
{
    bool frameValid = ipmbConnectionHeaderChecksumValidate(frame);
    if (false == frameValid)
    {
        // invalid connection header checksum.
        return false;
    }

    // data checksum validation.
    frameValid = ipmbDataChecksumValidate(frame, length);
    if (false == frameValid)
    {
        // invalid data checksum.
        return false;
    }

    return true;
}
