#include <stdio.h>

extern int multi_add(const void *a, const void *b, void *res, int n_words);
extern int multi_sub(const void *a, const void *b, void *res, int n_words);
extern void multi_mult(const void *a, const void *b, void *res, int n_words);

int main()
{
    unsigned long long a[2] = {0xab43032bdeadbeef, 0};
    unsigned long long b[2] = {0x9beeff00dd00d420, 0};
    unsigned long long res[4] = {0, 0, 0, 0};

    puts("\nTesting multi_add");
    multi_add(a, b, res, 4);
    printf("%016llx%016llx\n", a[1], a[0]);
    printf("%016llx%016llx\n", b[1], b[0]);
    printf("%016llx%016llx\n", res[1], res[0]);
    if (res[0] != 0x4732022cbbae930f || res[1] != 0x0000000000000001) {
        printf("multi_add failed!");
    }

    puts("\nTesting multi_sub");
    multi_sub(a, b, res, 4);
    printf("%016llx%016llx\n", a[1], a[0]);
    printf("%016llx%016llx\n", b[1], b[0]);
    printf("%016llx%016llx\n", res[1], res[0]);
    if (res[0] != 0xf54042b01aceacf || res[1] != 0) {
        puts("multi_sub failed!");
    }
    
    puts("\nTesting multi_mult");
    multi_mult(a, b, res, 4);
    printf("%016llx%016llx\n", a[1], a[0]);
    printf("%016llx%016llx\n", b[1], b[0]);
    printf("%016llx%016llx%016llx%016llx\n", res[3], res[2], res[1], res[0]);
    if (res[0] != 0xe9ec8b80ad5c9e0 || res[1] != 0x685175d0d69e5297) {
        puts("multi_mult failed!");
    }
}
