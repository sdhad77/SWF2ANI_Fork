package com.stintern.swf2ani.utils.datatype
{
    public class FrameData
    {
        private var _name:String;
        private var _sceneName:String;
        private var _frameX:Number;
        private var _frameY:Number;
        private var _frameWidth:Number;
        private var _frameHeight:Number;
        private var _rotate:Boolean = false;
        private var _type:String;
        
        public function FrameData()
        {
        }
        
        public function get name():String                { return _name;        }
        public function get sceneName():String           { return _sceneName;   }
        public function get rotate():Boolean             { return _rotate;      }
        public function get frameX():Number              { return _frameX;      }
        public function get frameY():Number              { return _frameY;      }
        public function get frameWidth():Number          { return _frameWidth;  }
        public function get frameHeight():Number         { return _frameHeight; }
        public function get type():String                { return _type;        }
        
        public function set name(value:String):void        { _name        = value; }
        public function set sceneName(value:String):void   { _sceneName   = value; }
        public function set rotate(value:Boolean):void     { _rotate      = value; }
        public function set frameX(value:Number):void      { _frameX      = value; }
        public function set frameY(value:Number):void      { _frameY      = value; }
        public function set frameWidth(value:Number):void  { _frameWidth  = value; }
        public function set frameHeight(value:Number):void { _frameHeight = value; }
        public function set type(value:String):void        { _type        = value; }
    }
}