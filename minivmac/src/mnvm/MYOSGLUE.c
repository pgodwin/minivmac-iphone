/*
 MYOSGLUE.c
 
 Copyright (C) 2006 Paul C. Pratt
 
 You can redistribute this file and/or modify it under the terms
 of version 2 of the GNU General Public License as published by
 the Free Software Foundation.  You should have received a copy
 of the license along with this file; see the file COPYING.
 
 This file is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 license for more details.
 */

/*
 MY Operating System GLUE
 */

#include "CNFGRAPI.h"
#include "SYSDEPNS.h"
#include "ENDIANAC.h"

#include "MYOSGLUE.h"

EXPORTFUNC blnr InitEmulation(void);
IMPORTPROC DoEmulateOneTick(void);

//IMPORTFUNC blnr ScreenFindChanges(si3b TimeAdjust, si4b *top, si4b *left, si4b * bottom, si4b *right);

//IMPORTFUNC blnr ScreenFindChanges(ui3p screencurrentbuff,
//                                  si3b TimeAdjust, si4b *top, si4b *left, si4b *bottom, si4b *right);

IMPORTPROC DoEmulateExtraTime(void);

//GLOBALVAR char *screencomparebuff = nullpr;

//GLOBALVAR ui4b *RAM = nullpr;

//GLOBALVAR ui4b *ROM = nullpr;

//GLOBALVAR ui4b CurMouseV = 0;
//GLOBALVAR ui4b CurMouseH = 0;
GLOBALVAR ui3b CurMouseButton = falseblnr;

//GLOBALVAR ui5b theKeys[4];

#ifndef WantInitSpeedValue
    #define WantInitSpeedValue 3
#endif

//GLOBALVAR ui3b SpeedValue = WantInitSpeedValue;

GLOBALVAR blnr SpeedLimit = (WantInitSpeedValue != -1);

#if EnableMouseMotion
//GLOBALVAR blnr HaveMouseMotion = falseblnr;
//
GLOBALVAR ui4b MouseMotionV = 0;
GLOBALVAR ui4b MouseMotionH = 0;
#endif

#if MySoundEnabled
#ifndef MySoundFullScreenOnly
#define MySoundFullScreenOnly 0
#endif
#endif

#ifndef EnableDragDrop
#define EnableDragDrop 1
#endif

//LOCALVAR blnr RequestMacOff = falseblnr;
//
//GLOBALVAR blnr ForceMacOff = falseblnr;
//
//GLOBALVAR blnr WantMacInterrupt = falseblnr;
//
//GLOBALVAR blnr WantMacReset = falseblnr;

//GLOBALVAR ui5b vSonyWritableMask = 0;
//GLOBALVAR ui5b vSonyInsertedMask = 0;
//GLOBALVAR ui5b vSonyMountedMask = 0;

#if IncludeSonyRawMode
//GLOBALVAR blnr vSonyRawMode = falseblnr;
#endif

#if IncludePbufs
//GLOBALVAR ui5b PbufAllocatedMask;
//GLOBALVAR ui5b PbufSize[NumPbufs];
#endif

#if IncludeSonyNew
//GLOBALVAR blnr vSonyNewDiskWanted = falseblnr;
//GLOBALVAR ui5b vSonyNewDiskSize;
#endif

#if IncludeSonyNameNew
//GLOBALVAR ui4b vSonyNewDiskName = NotAPbuf;
#endif

//GLOBALVAR ui5b CurMacDateInSeconds = 0;
//GLOBALVAR ui5b CurMacLatitude = 0;
//GLOBALVAR ui5b CurMacLongitude = 0;
//GLOBALVAR ui5b CurMacDelta = 0;

#if IncludePbufs
//LOCALFUNC blnr FirstFreePbuf(ui4b *r)
//{
//	si4b i;
//    
//	for (i = 0; i < NumPbufs; ++i) {
//		if (! PbufIsAllocated(i)) {
//			*r = i;
//			return trueblnr;
//		}
//	}
//	return falseblnr;
//}
#endif

#if IncludePbufs
//LOCALPROC PbufNewNotify(ui4b Pbuf_No, ui5b count)
//{
//	PbufSize[Pbuf_No] = count;
//	PbufAllocatedMask |= ((ui5b)1 << Pbuf_No);
//}
#endif

#if IncludePbufs
//LOCALPROC PbufDisposeNotify(ui4b Pbuf_No)
//{
//	PbufAllocatedMask &= ~ ((ui5b)1 << Pbuf_No);
//}
#endif

//LOCALFUNC blnr FirstFreeDisk(ui4b *Drive_No)
//{
//	si4b i;
//    
//	for (i = 0; i < NumDrives; ++i) {
//		if (! vSonyIsInserted(i)) {
//			*Drive_No = i;
//			return trueblnr;
//		}
//	}
//	return falseblnr;
//}

//GLOBALFUNC blnr AnyDiskInserted(void)
//{
//	si4b i;
//    
//	for (i = 0; i < NumDrives; ++i) {
//		if (vSonyIsInserted(i)) {
//			return trueblnr;
//		}
//	}
//	return falseblnr;
//}

//LOCALPROC DiskInsertNotify(ui4b Drive_No, blnr locked)
//{
//	vSonyInsertedMask |= ((ui5b)1 << Drive_No);
//	if (! locked) {
//		vSonyWritableMask |= ((ui5b)1 << Drive_No);
//	}
//}

//LOCALPROC DiskEjectedNotify(ui4b Drive_No)
//{
//	vSonyWritableMask &= ~ ((ui5b)1 << Drive_No);
//	vSonyInsertedMask &= ~ ((ui5b)1 << Drive_No);
//	vSonyMountedMask &= ~ ((ui5b)1 << Drive_No);
//}

FORWARDPROC HaveChangedScreenBuff(si4b top, si4b left, si4b bottom, si4b right);
//EXPORTPROC Screen_OutputFrame(ui3p screencurrentbuff);


#if MySoundEnabled
#define kLn2SoundBuffers 4 /* kSoundBuffers must be a power of two */
#define kSoundBuffers (1 << kLn2SoundBuffers)
#define kSoundBuffMask (kSoundBuffers - 1)

#define DesiredMinFilledSoundBuffs 3
/*
 if too big then sound lags behind emulation.
 if too small then sound will have pauses.
 */

#define kLnOneBuffLen 9
#define kLnAllBuffLen (kLn2SoundBuffers + kLnOneBuffLen)
#define kOneBuffLen (1UL << kLnOneBuffLen)
#define kAllBuffLen (1UL << kLnAllBuffLen)
#define kLnOneBuffSz (kLnOneBuffLen + kLn2SoundSampSz - 3)
#define kLnAllBuffSz (kLnAllBuffLen + kLn2SoundSampSz - 3)
#define kOneBuffSz (1UL << kLnOneBuffSz)
#define kAllBuffSz (1UL << kLnAllBuffSz)
#define kOneBuffMask (kOneBuffLen - 1)
#define kAllBuffMask (kAllBuffLen - 1)
#define dbhBufferSize (kAllBuffSz + kOneBuffSz)

#define dbglog_SoundStuff 0
#define dbglog_SoundBuffStats (dbglog_HAVE && 0)

LOCALVAR tpSoundSamp TheSoundBuffer = nullpr;
volatile static ui4b ThePlayOffset;
volatile static ui4b TheFillOffset;
volatile static blnr wantplaying;
volatile static ui4b MinFilledSoundBuffs;
#if dbglog_SoundBuffStats
LOCALVAR ui4b MaxFilledSoundBuffs;
#endif
LOCALVAR ui4b TheWriteOffset;

#if MySoundRecenterSilence
#define SilentBlockThreshold 96
LOCALVAR trSoundSamp LastSample = 0x00;
LOCALVAR trSoundSamp LastModSample;
LOCALVAR ui4r SilentBlockCounter;
#endif

LOCALPROC RampSound(tpSoundSamp p,
                    trSoundSamp BeginVal, trSoundSamp EndVal)
{
	int i;
	ui5r v = (((ui5r)BeginVal) << kLnOneBuffLen) + (kLnOneBuffLen >> 1);
    
	for (i = kOneBuffLen; --i >= 0; ) {
		*p++ = v >> kLnOneBuffLen;
		v = v + EndVal - BeginVal;
	}
}

#if 4 == kLn2SoundSampSz
LOCALPROC ConvertSoundBlockToNative(tpSoundSamp p)
{
	int i;
    
	for (i = kOneBuffLen; --i >= 0; ) {
		*p++ -= 0x8000;
	}
}
#else
#define ConvertSoundBlockToNative(p)
#endif

#if 4 == kLn2SoundSampSz
#define ConvertSoundSampleToNative(v) ((v) + 0x8000)
#else
#define ConvertSoundSampleToNative(v) (v)
#endif


LOCALPROC MySound_WroteABlock(void)
{
#if MySoundRecenterSilence || (4 == kLn2SoundSampSz)
	ui4b PrevWriteOffset = TheWriteOffset - kOneBuffLen;
	tpSoundSamp p = TheSoundBuffer + (PrevWriteOffset & kAllBuffMask);
#endif
    
#if MySoundRecenterSilence
	int i;
	tpSoundSamp p0;
	trSoundSamp lastv = LastSample;
	blnr GotSilentBlock = trueblnr;
    
	p0 = p;
	for (i = kOneBuffLen; --i >= 0; ) {
		trSoundSamp v = *p++;
		if (v != lastv) {
			LastSample = *(p0 + kOneBuffLen - 1);
			GotSilentBlock = falseblnr;
			goto label_done;
		}
	}
label_done:
	p = p0;
    
	if (GotSilentBlock) {
		if ((! wantplaying) && (PrevWriteOffset == ThePlayOffset)) {
			TheWriteOffset = PrevWriteOffset;
			return; /* forget this block */
		}
		++SilentBlockCounter;
#if dbglog_SoundStuff
		fprintf(stderr, "GotSilentBlock %d\n", SilentBlockCounter);
#endif
		if (SilentBlockCounter >= SilentBlockThreshold) {
			trSoundSamp NewModSample;
            
			if (SilentBlockThreshold == SilentBlockCounter) {
				LastModSample = LastSample;
			} else {
				SilentBlockCounter = SilentBlockThreshold;
                /* prevent overflow */
			}
#if 3 == kLn2SoundSampSz
			if (LastModSample > kCenterSound) {
				NewModSample = LastModSample - 1;
			} else if (LastModSample < kCenterSound) {
				NewModSample = LastModSample + 1;
			} else {
				NewModSample = kCenterSound;
			}
#elif 4 == kLn2SoundSampSz
			if (LastModSample > kCenterSound + 0x0100) {
				NewModSample = LastModSample - 0x0100;
			} else if (LastModSample < kCenterSound - 0x0100) {
				NewModSample = LastModSample + 0x0100;
			} else {
				NewModSample = kCenterSound;
			}
#else
#error "unsupported kLn2SoundSampSz"
#endif
#if dbglog_SoundStuff
			fprintf(stderr, "LastModSample %d\n", LastModSample);
#endif
			RampSound(p, LastModSample, NewModSample);
			LastModSample = NewModSample;
		}
	} else {
#if EnableAutoSlow && 0
		QuietEnds();
#endif
        
		if (SilentBlockCounter >= SilentBlockThreshold) {
			tpSoundSamp pramp;
			ui4b TotLen = TheWriteOffset
            - ThePlayOffset;
			ui4b TotBuffs = TotLen >> kLnOneBuffLen;
            
			if (TotBuffs >= 3) {
				pramp = TheSoundBuffer
                + ((PrevWriteOffset - kOneBuffLen) & kAllBuffMask);
			} else {
				pramp = p;
				p = TheSoundBuffer + (TheWriteOffset & kAllBuffMask);
				MyMoveBytes((anyp)pramp, (anyp)p, kOneBuffSz);
				TheWriteOffset += kOneBuffLen;
			}
#if dbglog_SoundStuff
			fprintf(stderr, "LastModSample %d\n", LastModSample);
			fprintf(stderr, "LastSample %d\n", LastSample);
#endif
			RampSound(pramp, LastModSample, LastSample);
			ConvertSoundBlockToNative(pramp);
		}
		SilentBlockCounter = 0;
	}
#endif
    
	ConvertSoundBlockToNative(p);
    
	if (wantplaying) {
		TheFillOffset = TheWriteOffset;
	} else if (((TheWriteOffset - ThePlayOffset) >> kLnOneBuffLen) < 12)
	{
		/* just wait */
	} else {
		TheFillOffset = TheWriteOffset;
		wantplaying = trueblnr;
		MySound_BeginPlaying();
        //MySound_Start();
	}
    
#if dbglog_SoundBuffStats
	{
		ui4b ToPlayLen = TheFillOffset
        - ThePlayOffset;
		ui4b ToPlayBuffs = ToPlayLen >> kLnOneBuffLen;
        
		if (ToPlayBuffs > MaxFilledSoundBuffs) {
			MaxFilledSoundBuffs = ToPlayBuffs;
		}
	}
#endif
}



//GLOBALFUNC tpSoundSamp MySound_BeginWrite(ui4r n, ui4r *actL)
//{
//	ui4b ToFillLen = kAllBuffLen - (TheWriteOffset - ThePlayOffset);
//	ui4b WriteBuffContig =
//    kOneBuffLen - (TheWriteOffset & kOneBuffMask);
//    
//	if (WriteBuffContig < n) {
//		n = WriteBuffContig;
//	}
//	if (ToFillLen < n) {
//		/* overwrite previous buffer */
//		TheWriteOffset -= kOneBuffLen;
//	}
//    
//	*actL = n;
//	return TheSoundBuffer + (TheWriteOffset & kAllBuffMask);
//}
#endif


//#include "INTLCHAR.h"

#include "COMOSGLU.h"
IMPORTFUNC ui3p GetCurDrawBuff(void);

GLOBALVAR ui3p ScalingBuff = nullpr;


GLOBALPROC UpdateLuminanceCopy(ui3p* destination, si4b top, si4b left,
                              si4b bottom, si4b right)
{
	int i;
	int j;
	ui5b t0;
    
    
	UnusedParam(left);
	UnusedParam(right);
#if 0 != vMacScreenDepth
	if (UseColorMode) {
#if vMacScreenDepth < 4
		ui5b CLUT_final[CLUT_size];
#endif
		ui3b *p1 = GetCurDrawBuff()
        + (ui5r)vMacScreenByteWidth * top;
		ui5b *p2 = (ui5b *)destination
        + (ui5r)vMacScreenWidth * top;
        
#if vMacScreenDepth < 4
		for (i = 0; i < CLUT_size; ++i) {
			CLUT_final[i] = (((long)CLUT_reds[i] & 0xFF00) << 16)
            | (((long)CLUT_greens[i] & 0xFF00) << 8)
            | ((long)CLUT_blues[i] & 0xFF00);
		}
#endif
        
		for (i = bottom - top; --i >= 0; ) {
#if 4 == vMacScreenDepth
			for (j = vMacScreenWidth; --j >= 0; ) {
				t0 = do_get_mem_word(p1);
				p1 += 2;
				*p2++ =
                ((t0 & 0x7C00) << 17) |
                ((t0 & 0x7000) << 12) |
                ((t0 & 0x03E0) << 14) |
                ((t0 & 0x0380) << 9) |
                ((t0 & 0x001F) << 11) |
                ((t0 & 0x001C) << 6);
#if 0
                ((t0 & 0x7C00) << 9) |
                ((t0 & 0x7000) << 4) |
                ((t0 & 0x03E0) << 6) |
                ((t0 & 0x0380) << 1) |
                ((t0 & 0x001F) << 3) |
                ((t0 & 0x001C) >> 2);
#endif
			}
#elif 5 == vMacScreenDepth
			for (j = vMacScreenWidth; --j >= 0; ) {
				t0 = do_get_mem_long(p1);
				p1 += 4;
				*p2++ = t0 << 8;
			}
#else
			for (j = vMacScreenByteWidth; --j >= 0; ) {
				t0 = *p1++;
#if 1 == vMacScreenDepth
				*p2++ = CLUT_final[t0 >> 6];
				*p2++ = CLUT_final[(t0 >> 4) & 0x03];
				*p2++ = CLUT_final[(t0 >> 2) & 0x03];
				*p2++ = CLUT_final[t0 & 0x03];
#elif 2 == vMacScreenDepth
				*p2++ = CLUT_final[t0 >> 4];
				*p2++ = CLUT_final[t0 & 0x0F];
#elif 3 == vMacScreenDepth
				*p2++ = CLUT_final[t0];
#endif
			}
#endif
		}
	} else
#endif
	{
		int k;
		ui3b *p1 = GetCurDrawBuff()
        + (ui5r)vMacScreenMonoByteWidth * top;
		ui3b *p2 = (ui3b*)destination + (ui5r)vMacScreenWidth * top;
        
		for (i = bottom - top; --i >= 0; ) {
			for (j = vMacScreenMonoByteWidth; --j >= 0; ) {
				t0 = *p1++;
				for (k = 8; --k >= 0; ) {
					*p2++ = ((t0 >> k) & 0x01) - 1;
				}
			}
		}
	}
}

GLOBALPROC Keyboard_UpdateKeyMap3(int key, blnr down)
{
    Keyboard_UpdateKeyMap(key, down);
}

#include "PROGMAIN.h"

GLOBALPROC ReserveAllocAll(void)
{
#if dbglog_HAVE
	dbglog_ReserveAlloc();
#endif
	ReserveAllocOneBlock(&ROM, kROM_Size, 5, falseblnr);
	ReserveAllocOneBlock(&screencomparebuff,
                         vMacScreenNumBytes, 5, trueblnr);
	//ReserveAllocOneBlock(&CntrlDisplayBuff,
    //                     vMacScreenNumBytes, 5, falseblnr);
//	ReserveAllocOneBlock(&ScalingBuff, vMacScreenNumPixels
//#if 0 != vMacScreenDepth
//                         * 4
//#endif
//                         , 5, falseblnr);
#if MySoundEnabled
	ReserveAllocOneBlock((ui3p *)&TheSoundBuffer,
                         dbhBufferSize, 5, falseblnr);
#endif
    
	EmulationReserveAlloc();
}

GLOBALFUNC blnr AllocMyMemory(void)
{
	uimr n;
	blnr IsOk = falseblnr;
    
	ReserveAllocOffset = 0;
	ReserveAllocBigBlock = nullpr;
	ReserveAllocAll();
	n = ReserveAllocOffset;
	ReserveAllocBigBlock = (ui3p)calloc(1, n);
	if (NULL == ReserveAllocBigBlock) {
		//MacMsg(kStrOutOfMemTitle, kStrOutOfMemMessage, trueblnr);
	} else {
		ReserveAllocOffset = 0;
		ReserveAllocAll();
		if (n != ReserveAllocOffset) {
			/* oops, program error */
		} else {
			IsOk = trueblnr;
		}
	}
    
	return IsOk;
}


#include "STRCONST.h"



#include "CONTROLM.h"


#include "PLATGLUE.h"
