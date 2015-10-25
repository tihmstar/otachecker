//
//  main.m
//  otachecker
//
//  Created by tihmstar on 21.10.15.
//  Copyright © 2015 tihmstar. All rights reserved.
//

#import <Foundation/Foundation.h>

void printOtas(NSDictionary *softwareupdates){
    NSMutableDictionary *res = [NSMutableDictionary new];
    printf("checking what ota versions are being signed\n");
    NSArray *otas = [softwareupdates valueForKey:@"Assets"];
    
    for (NSDictionary *obj in otas) {
        id allowableOTA;
        if ((allowableOTA = [obj valueForKey:@"AllowableOTA"]) && [allowableOTA boolValue] == FALSE) continue;
        
        NSString *version = [obj valueForKey:@"OSVersion"];
        NSArray *devices = [obj valueForKey:@"SupportedDevices"];
        
        NSMutableArray *resdevs = [res valueForKey:version];
        if (!resdevs) resdevs = [NSMutableArray new];
        
        for (NSString *dev in devices) if (![resdevs containsObject:dev]) [resdevs addObject:dev];
        
        [res setValue:resdevs forKey:version];
    }
    
    printf("Apple currently signs following ota firmwares:\n");
    for (NSString *key in [[res allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
        NSArray *devs = [res valueForKey:key];
        printf("[iOS %s]:\n",[key UTF8String]);
        
        char currentDevice[0x100];
        memset(currentDevice, 0, 0x100);
        
        for (NSString *device in [devs sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
            const char *c_device = [device UTF8String];
            if (*currentDevice != '\0' && strncmp(currentDevice, c_device, strlen(currentDevice)) != 0){
                memset(currentDevice, 0, 0x100);
                printf("\n");
            }
            
            if (*currentDevice == '\0') {
                int i = 0;
                while (isalpha(c_device[(i = (int)strlen(currentDevice))])) currentDevice[i] = c_device[i];
            }
            
            printf("%s ",c_device);
        }
        printf("\n\n");
    }
    printf("\n");
}

void printhelp(){
    printf("otachecker:\n");
    printf("default (no args): shows what ota firmware is signed for which devices\n");
    printf("   -h\t\tshows this help\n");
    printf("   -d\t\tset devices (for -u)\n");
    printf("   -i\t\tset ios version (for -u)\n");
    printf("   -u\t\tprints url of ota zip (requires -i and -d)\n");
    printf("\n\n");
}

void printURL(NSString *device, NSString *ios, NSDictionary *softwareupdates){
    NSArray *otas = [softwareupdates valueForKey:@"Assets"];
    
    printf("checking ota url for %s %s\n",[device UTF8String],[ios UTF8String]);
    
    for (NSDictionary *obj in otas) {
        NSString *version = [obj valueForKey:@"OSVersion"];
        NSArray *devices = [obj valueForKey:@"SupportedDevices"];
        
        if ([version isEqualToString:ios]) {
            if ([devices containsObject:device]) {
                NSString *url = [[obj valueForKey:@"__BaseURL"] stringByAppendingString:[obj valueForKey:@"__RelativePath"]];
                printf("ota url for %s %s: %s",[device UTF8String],[ios UTF8String],[url UTF8String]);
                exit(0);
            }
        }
    }
    printf("ota for %s %s is not signed\n",[device UTF8String],[ios UTF8String]);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        printf("downloading com_apple_MobileAsset_SoftwareUpdate.xml\n");
        NSDictionary *softwareupdates = [[NSDictionary alloc] initWithContentsOfURL:[NSURL URLWithString:@"http://mesu.apple.com/assets/com_apple_MobileAsset_SoftwareUpdate/com_apple_MobileAsset_SoftwareUpdate.xml"]];
        
        BOOL wantsURL = false;
        NSString *device;
        NSString *ios;
        
        char c;
        if (argc == 1) {
            printOtas(softwareupdates);
            exit(0);
        }
        
        while ((c = getopt (argc, argv, "hui:d:")) != -1){
            switch (c){
                case 'h':
                    printhelp();
                    break;
                
                case 'd':
                    device = [[NSString alloc] initWithCString:optarg encoding:NSUTF8StringEncoding];
                    break;
                
                case 'i':
                    ios = [[NSString alloc] initWithCString:optarg encoding:NSUTF8StringEncoding];
                    break;
                  
                case 'u':
                    wantsURL = TRUE;
                    break;
                    
                case '?':
                    if (optopt == 'd' || optopt == 'i'){
                        printf("Error: %c requires argument\n",optopt);
                        
                    }
                    exit(1);
                    break;
                    
                default:
                    printOtas(softwareupdates);
                    exit(0);
            }
        }
        
        if (wantsURL){
            if (!device || !ios) {
                printf("Error: -d and -i required for -u\n");
                exit(1);
            }
            printURL(device,ios,softwareupdates);
        }
        
    }
    return 0;
}





