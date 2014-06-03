package com.stintern.swf2ani.utils.datatype
{
    public class Node
    {
        private var _left:Node;
        private var _right:Node;
        private var _rect:Rect;
        private var _filled:Boolean;
        
        public function Node()
        {
        }
        
        public function get filled():Boolean            {   return _filled;     }
        public function set filled(value:Boolean):void  {   _filled = value;    }
        public function get rect():Rect                 {   return _rect;       }
        public function set rect(value:Rect):void       {   _rect = value;      }
        public function get right():Node                {   return _right;      }
        public function set right(value:Node):void      {   _right = value;     }
        public function get left():Node                 {   return _left;       }
        public function set left(value:Node):void       {   _left = value;      }
    }
}