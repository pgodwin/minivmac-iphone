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


//#include "INTLCHAR.h"

#include "COMOSGLU.h"
IMPORTFUNC ui3p GetCurDrawBuff(void);

/* Draw the screen */
//LOCALPROC Screen_Draw(si3b TimeAdjust)
//{
//	si4b top;
//	si4b left;
//	si4b bottom;
//	si4b right;
//    
//	if (ScreenFindChanges(TimeAdjust,
//                          &top, &left, &bottom, &right))
//	{
//		HaveChangedScreenBuff(top, left, bottom, right);
//	}
//    
//}

//LOCALPROC SetLongs(ui5b *p, long n)
//{
//	long i;
//    
//	for (i = n; --i >= 0; ) {
//		*p++ = (ui5b) -1;
//	}
//}

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
		ui3b *p2 = destination + (ui5r)vMacScreenWidth * top;
        
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
