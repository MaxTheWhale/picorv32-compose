#include <stdio.h>

extern int multi_add(const void *a, const void *b, void *res, int n_words);
extern int multi_sub(const void *a, const void *b, void *res, int n_words);

int main()
{
    unsigned long long a[2] = {0xab43032bdeadbeef, 0};
    unsigned long long b[2] = {0x9beeff00dd00d420, 0};
    unsigned long long res[2];
    printf("%016llx%016llx\n", a[1], a[0]);
    printf("%016llx%016llx\n", b[1], b[0]);
    printf("%016llx%016llx\n", res[1], res[0]);
    multi_add(a, b, res, 4);
    printf("%016llx%016llx\n", a[1], a[0]);
    printf("%016llx%016llx\n", b[1], b[0]);
    printf("%016llx%016llx\n", res[1], res[0]);
    multi_sub(a, b, res, 4);
    printf("%016llx%016llx\n", a[1], a[0]);
    printf("%016llx%016llx\n", b[1], b[0]);
    printf("%016llx%016llx\n", res[1], res[0]);
}
