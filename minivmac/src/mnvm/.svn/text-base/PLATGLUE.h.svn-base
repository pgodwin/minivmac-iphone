
LOCALPROC HaveChangedScreenBuff(si4b top, si4b left, si4b bottom, si4b right) {
    // this is never used
}

GLOBALPROC notifyDiskInserted(ui4b Drive_No, blnr locked) {
    DiskInsertNotify(Drive_No, locked);
}

GLOBALPROC notifyDiskEjected(ui4b Drive_No) {
    DiskEjectedNotify(Drive_No);
}

GLOBALFUNC blnr getFirstFreeDisk(ui4b *Drive_No) {
    return FirstFreeDisk(Drive_No);
}

GLOBALPROC drawScreen(si3b TimeAdjust) {
    Screen_Draw(TimeAdjust);
}
