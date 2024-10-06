#include <stdio.h>
#include <stdlib.h>

#define BUF_LEN 4096*4

void read_test() {
	char buf[BUF_LEN];
	for (int i = 0; i < BUF_LEN; i++) {
		buf[i] = i;
	}
	FILE *fp = fopen("/dev/softmc_cdev", "r");
	if (!fp) {
		printf("No file\n");
		return;
	}
	printf("Reading once\n");
	fread(buf, sizeof(char), BUF_LEN, fp);
	printf("%s", buf);
	printf("\n--------\n");
	fread(buf, sizeof(char), BUF_LEN, fp);
	printf("%s", buf);
	printf("\n--------\n");
	fclose(fp);
}

void write_test() {
	char buf[BUF_LEN];
	for (int i = 0; i < BUF_LEN; i++) {
		buf[i] = i;
	}
	FILE *fp = fopen("/dev/softmc_cdev", "w");
	if (!fp) {
		printf("No file\n");
		return;
	}
	fwrite(buf, sizeof(char), BUF_LEN, fp);
	fclose(fp);
}

int main() {
	write_test();
	return 0;
}