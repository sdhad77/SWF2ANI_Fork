package com.stintern.swf2ani.utils.datatype
{
    import flash.geom.Rectangle;

    public class Rect extends Rectangle
    {	
        public function Rect(x:int, y:int, width:int, height:int)
        {
            super(x,y,width,height);
        }
        
        /**
         * width와 height를 이용하여 두 사각형의 크기를 비교하고 같을 경우 true 반환
         * @param rc 비교할 Rect
         * @return 두 사각형의 크기가 같으면 true
         */
        public function isSameSize(rc:Rect):Boolean
        {
            if((rc.width == this.width) && (rc.height == this.height)) return true;
            else return false;
        }
        
        /**
         * width와 height를 이용하여 두 사각형의 크기를 비교하고, this의 사각형이 더 클 경우 true 반환
         * @param rc 비교할 Rect
         * @return 호출된(this)의 크기가 더 크면 true
         */
        public function isTooBig(rc:Rect):Boolean
        {
            if((this.width > rc.width) || (this.height > rc.height)) return true;
            else return false;
        }
    }
}