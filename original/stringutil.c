#include "copyright.h"

/* String utilities */

#include <ctype.h>

#include "externs.h"

#define DOWNCASE(x) (isupper(x) ? tolower(x) : (x))

int string_compare(const char *s1, const char *s2)
{
    while(*s1 && *s2 && DOWNCASE(*s1) == DOWNCASE(*s2)) s1++, s2++;

    return(DOWNCASE(*s1) - DOWNCASE(*s2));
}

int string_prefix(const char *string, const char *prefix)
{
    while(*string && *prefix && DOWNCASE(*string) == DOWNCASE(*prefix))
	string++, prefix++;
    return *prefix == '\0';
}

/* accepts only nonempty matches starting at the beginning of a word */
const char *string_match(const char *src, const char *sub)
{
    if(*sub != '\0') {
	while(*src) {
	    if(string_prefix(src, sub)) return src;
	    /* else scan to beginning of next word */
	    while(*src && isalnum(*src)) src++;
	    while(*src && !isalnum(*src)) src++;
	}
    }

    return 0;
}

