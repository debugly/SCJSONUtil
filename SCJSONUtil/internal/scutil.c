//
//  scutil.c
//  SCJSONUtil
//
//  Created by qianlongxu on 2020/11/15.
//

#include "scutil.h"
#include <string.h>

bool QLCStrEqual(char *v1,char *v2) {
    if (NULL == v1 || NULL == v2) {
        return 0;
    }
    return 0 == strcmp(v1, v2);
}
