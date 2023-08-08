#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>
#include <asm/ioctl.h>
#include <sys/ioctl.h> /* For ioctl */
#include <fcntl.h>
#include <poll.h>
#include <time.h>
#include <sys/time.h>
#include "vdm_module.h"

#define DEFAULT_RX_BUFF_SIZE 64*1024
#define DEFAULT_TX_BUFF_SIZE 64*1024

bdf_arg_t bdf;
uint32_t rxbufersize=DEFAULT_RX_BUFF_SIZE;
uint32_t txbufersize=DEFAULT_TX_BUFF_SIZE, txsize;
int DataIdx;

#define SEND_DATA_BUFF_SIZE 8192
uint8_t data_to_send[SEND_DATA_BUFF_SIZE+1];

#define MTU 80 //increased by 4 

struct mctp_pcie_packet {
	struct {
		uint32_t hdr[4];
		uint32_t payload[(MTU - 16)>>2];
	} data;
	uint32_t size;
};

typedef enum
{
	Mode_Receive=0,
	Mode_Send,
	Mode_Receive_Poll,
} Mode_t;

Mode_t WorkingMode;

uint8_t received_packet_buffer[64*1024];


int main (int argc, char **argv)
{
	static int packet_count=0;
	long ret;
	int packet_length;
	int timeout = 0, i, writelen, cnt;
	int fd = -1;
	struct pollfd fds[1];
	struct timeval t0,t1;
	int total_size = 0;
	double diff;
	mctp_pcie_packet pkt;

	for (i = 1; i < argc; i+=2) {
		if (i+1>=argc)
			abort();

		if( 0 == strcmp(argv[i],"--bus")) {
			bdf.bus=atoi(argv[i+1]);
		} else if (0 == strcmp(argv[i],"--dev")) {
			bdf.device=atoi(argv[i+1]);
		} else if (0 == strcmp(argv[i],"--func")) {
			bdf.function=atoi(argv[i+1]);
		} else if (0 == strcmp(argv[i],"--txbufsize")) {
			txbufersize=atoi(argv[i+1]);
		} else if (0 == strcmp(argv[i],"--txsize")) {
			txsize=atoi(argv[i+1]);
		} else if (0 == strcmp(argv[i],"--mode")) {
			if (0 == strcmp(argv[i+1],"receive")) {
				WorkingMode = Mode_Receive;
			} else if (0 == strcmp(argv[i+1],"receive_poll")) {
				WorkingMode=Mode_Receive_Poll;
			} else if (0 == strcmp(argv[i+1],"send")) {
				WorkingMode = Mode_Send;
			}
			printf("WorkingMode = %d\n", WorkingMode );
		}
	}

	fd = open("/dev/vdm", O_RDWR, 0);
	fds[0].fd = fd;
	fds[0].events = POLLIN | POLLRDNORM;
	if(fd < 0) {
		printf(" Opening VDM device Failed\n");
		return -1;
	}

	ret = ioctl(fd, PCIE_VDM_REINIT, 0);
	if (ret < 0) {
		printf("Cannot init, errno = %d \n", ret);
		goto error;
	}

	printf("bdf.bus 0x%x\n", bdf.bus);
	printf("bdf.device 0x%x\n", bdf.device);
	printf("bdf.function 0x%x\n", bdf.function);

	ret = ioctl(fd, PCIE_VDM_SET_BDF, &bdf);
	if (ret < 0) {
		printf("PCIE_VDM_SET_BDF ioctl failed. Return code: %d\n", ret);
		goto error;
	}

	ret = ioctl(fd, PCIE_VDM_SET_TRANSMIT_BUFFER_SIZE, txbufersize);
	if (ret < 0) {
		printf("PCIE_VDM_SET_TRANSMIT_BUFFER_SIZE ioctl failed. Return code: %d\n", ret);
		goto error;
	}

	if (Mode_Receive == WorkingMode) {
		while (1) {
			ret = read(fd,&received_packet_buffer[0],4);
			if(4 == ret) {
				printf("Header -> 0x%x 0x%x 0x%x 0x%x\n", received_packet_buffer[0], received_packet_buffer[1],
					   received_packet_buffer[2],received_packet_buffer[3]);
				packet_length = (received_packet_buffer[2] << 8) + received_packet_buffer[3]  + 4;// 4 for pcie header length
				printf("packet %d with length  %d \n", packet_count++ ,packet_length);
				packet_length=packet_length*4 ;// convert to bytes
				ret=read(fd,&received_packet_buffer[4],packet_length - 4 );
				for (i = 16 ; i < packet_length ; i+=4) {
					printf("Address %d = 0x%x 0x%x 0x%x 0x%x\n", i - 16, received_packet_buffer[i], received_packet_buffer[i+1],
						received_packet_buffer[i+2],received_packet_buffer[i+3]);
				}
			} else {
				sleep(5);
			}
		}
	} else if (Mode_Receive_Poll == WorkingMode) {
		i = 64*1024;
		while (1) {
			fds[0].events = POLLIN | POLLRDNORM;
			poll(fds, 1, -1);
			if (fds[0].revents & POLLIN) {
				ret = read(fd,&received_packet_buffer[0], i);
				printf("received %d\n", ret);
			}
		}
	} else {
		if (txsize < sizeof(pkt.data.payload)) {
			writelen = txsize;
		} else {
			writelen = sizeof(pkt.data.payload);
		}

		cnt = txsize / sizeof(pkt.data.payload);
		if (txsize % sizeof(pkt.data.payload)) {
			cnt+=1;
		}

		printf("writelen = %d cnt = %d \n", writelen, cnt);
		printf("bus = %d device = %d function=%d txbufersize=%d txsize=%d\n", bdf.bus,bdf.device, bdf.function, txbufersize, writelen * cnt);

		total_size = MTU * cnt;

		data_to_send[0] = 0x12;

		for (i=1; i < writelen + 1; i++) {
			data_to_send[i] = i % 256;
		}

		gettimeofday(&t0,NULL);
		for (i = 0; i < cnt; i++) {
			ret = write(fd, data_to_send, writelen);
			if (ret < 0) {
				printf("write failed. Return code: %d \n", ret );
				goto error;
			}
		}
		gettimeofday(&t1,NULL);
		diff=(t1.tv_sec - t0.tv_sec)*1000 + (t1.tv_usec - t0.tv_usec)/1000.0;

		printf("MTU size %d \n", MTU);
		printf("Total size sent %d \n", total_size);
		printf("Test measure  %10.5f msec\n", diff);
		printf("TX Performance %f MB/s \n", (float)((total_size/diff)*1000)/1024/1024);
	}

error:
	close(fd);
}
