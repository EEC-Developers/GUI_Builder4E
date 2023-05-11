OPT MODULE,OSVERSION=40

MODULE 'graphics/gfx','graphics/sprite','intuition/intuition',
    'utility/taglist'

-> TODO: Fix AGA and SuperAGA sprite support
CONST BITDEPTH=2
CONST BYTESPERPLANE=2
CONST BYTESPERROW=BYTESPERPLANE*BITDEPTH
CONST NUMCONTROLWORDS=2
CONST MINSPRITE=2
CONST SPRPALETTEMASK=6
CONST NUMPALETTEENTRIES=Shl(1,BITDEPTH)
-> TODO: Define as height of drag bar move gadget
CONST MOVEGADHEIGHT=0

#define SPRBUFSIZE(h) (((h)+NUMCONTROLWORDS)*BYTESPERROW)+MOVEGADHEIGHT
#define SPRPALETTEBASE(s) ((s) AND SPRPALETTEMASK)*NUMPALETTEENTRIES

EXPORT OBJECT toolbar PRIVATE
    sprite:PTR TO ExtSprite
    wndw:PTR TO Window
    buf
    scrn:PTR TO Screen
    bm:PTR TO BitMap
    spritenum:CHAR
    palettebase:CHAR
ENDOBJECT

-> Constructor for toolbar
-> height must be less than or equal to 512
-> tags is a taglist for AGA capabilities and SuperAGA on Apollo Core
PROC create(x,y,height,tags:PTR TO TagItem) OF toolbar
    DEF bufsize:REG,count:REG
    -> Allocate memory for BitMap data
    height:=height+MOVEGADHEIGHT
    bufsize:=SPRBUFSIZE(height)
    self.buf:=NewM(bufsize,MEMF_CHIP)
    -> generate BitMap structure from the sprite buffer
    self.bm:=[BYTESPERROW,height,BMF_INTERLEAVED,2,
        buf+BYTESPERROW,buf+BYTESPERROW+BYTESPERPLANE]:BitMap
    -> allocate sprite 2 or greater
    self.sprite:=NEW [
        self.buf,
        x,y,MINSPRITE
    ]:ExtSprite
    count:=MINSPRITE-1
    REPEAT
        INC count
        IF count>7 THEN Raise("SPR")
        self.spritenum:=GetExtSpriteA(self.sprite,[
            GSTAG_SPRITE_NUM,count,
            TAG_DONE,0
        ]:TagItem)
    UNTIL self.spritenum<>-1
    self.palettebase:=SPRPALETTEBASE(self.spritenum)
    -> Build a screen structure using the BitMap
    self.scrn:=OpenScreenTagList(NIL,[
        SA_Height,height,
        SA_Width,BYTESPERPLANE*8,
        SA_BitMap,self.bm,
        SA_Quiet,TRUE,
        SA_Behind,TRUE,
        SA_Depth,BITDEPTH,
        TAG_DONE,0
    ]:TagItem)
    -> open the actual window
    self.wndw:=OpenWindowTagList(NIL,[
        WA_LEFT,0,
        WA_TOP,0+MOVEGADHEIGHT,
        WA_WIDTH,BYTESPERPLANE*8,
        WA_HEIGHT,height,
        WA_SizeGadget,FALSE,
        WA_DragBar,FALSE,
        WA_CloseGadget,FALSE,
        WA_CustomScreen,TRUE,
        WA_NoCareRefresh,TRUE,
        WA_BackDrop,TRUE,
        WA_Borderless,TRUE,
        TAG_DONE,0
    ]:TagItem)
ENDPROC

PROC free() OF toolbar
    CloseWindow(self.wndw)
    CloseScreen(self.scrn)
    FreeSprite(self.spritenum)
    END self.bm,self.buf
ENDPROC
