# minivmac-iphone
A butchered fork of the Mini vMac for iPhone port.

# Archived
This was a "fun" project to port the then bleeding edge mini vmac Mac II emulation to iPhone + iPad. It compiled and (barely) worked back in 2011. 
I learned a lot, but didn't up persuing iOS development beyond this.

There are no builds of this version available, and I have neither the hardware, nor desire to create any builds. 

## Where to from here?
The original developer of minivmac-iphone has a much better, maintained port available at https://github.com/zydeco/minivmac4ios/. 

For those that are chasing support on old iOS 5 or earlier devices, I'd suggest forking zydeco's version and getting it building against an iOS 5 target. 
While I haven't looked into it, I'd imagine it should just be a matter of `#ifdef` out features that only exist in newer versions of iOS. 

It looks like zydeco has also done some work towards porting [Basilisk II to iOS](https://github.com/zydeco/macemu/tree/ios) - depending on
use case, that might be an even better place to start (after all Basilisk has sound support, dynamic resolution, potentially networking, 
file system sharing, etc). 

Lastly, those with older iOS devices might like to check out the [Legacy Jailbreak](https://www.reddit.com/r/LegacyJailbreak/) sub-reddit for
other apps, advice and tools. 
