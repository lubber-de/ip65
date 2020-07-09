///////////////////////////////////////////

// https://www.epochconverter.com/timezones

#define TIMEZONE_CODE "CET"
#define TIMEZONE_SECS 3600

#define NTP_SERVER "pool.ntp.org"

///////////////////////////////////////////

#include <cc65.h>
#include <time.h>
#include <fcntl.h>
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "../inc/ip65.h"

void error_exit(void)
{
  printf("- %s\n", ip65_strerror(ip65_error));
  exit(EXIT_FAILURE);
}

void confirm_exit(void)
{
  printf("\nPress any key ");
  cgetc();
}

int main(void)
{
  uint8_t eth_init = ETH_INIT_DEFAULT;
  uint32_t server;
  struct timespec time;

  strncpy(_tz.tzname, TIMEZONE_CODE,
          sizeof(_tz.tzname) - 1);
  _tz.timezone = TIMEZONE_SECS;

  if (doesclrscrafterexit())
  {
    atexit(confirm_exit);
  }

#ifdef __APPLE2__
  {
    int file;

    printf("\nSetting slot ");
    file = open("ethernet.slot", O_RDONLY);
    if (file != -1)
    {
      read(file, &eth_init, 1);
      close(file);
      eth_init &= ~'0';
    }
    printf("- %d\n", eth_init);
  }
#endif

  printf("\nInitializing ");
  if (ip65_init(eth_init))
  {
    error_exit();
  }

  printf("- Ok\n\nObtaining IP address ");
  if (dhcp_init())
  {
    error_exit();
  }

  printf("- Ok\n\nResolving %s ", NTP_SERVER);
  server = dns_resolve(NTP_SERVER);
  if (!server)
  {
    error_exit();
  }

  printf("- Ok\n\nGetting %s ", _tz.tzname);
  time.tv_sec = sntp_get_time(server);
  if (!time.tv_sec)
  {
    error_exit();
  }

  // Convert time from seconds since 1900 to
  // seconds since 1970 according to RFC 868
  time.tv_sec -= 2208988800UL;

  printf("- %s", ctime(&time.tv_sec));

  time.tv_nsec = 0;
  clock_settime(CLOCK_REALTIME, &time);

  return EXIT_SUCCESS;
}
