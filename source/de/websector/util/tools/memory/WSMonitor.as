/** 
* WSMonitor
* 
* @author  Jens Krause [www.websector.de]
* @date    10/01/07
* @see      http://www.websector.de/blog/2007/10/01/detecting-memory-leaks-in-flash-or-flex-applications-using-wsmonitor/
*/
package de.websector.util.tools.memory 
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.DropShadowFilter;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	
	import de.websector.util.tools.memory.Logo;
	
	import fl.controls.Button;
	public class WSMonitor extends Sprite
	{
		//
		// vars
		private var _memMinValue: uint = 0;
		private var _memMaxValue: uint = 0;
		private var _memCurrentValue: uint = 0;
		private var _memLastValue: uint = 0;		
		private var _firstRun: Boolean = true;
		//
		// const	
		private static const WIDTH: uint = 330;
		private static const HEIGHT: uint = 220;

		private static const FONT: String = "FFF Harmony";
				
		private static const GRAPH_AREA_DIFF: uint = 2;
		private static const GRAPH_AREA_WIDTH: uint = 308;
		private static const GRAPH_AREA_HEIGHT: uint = 120;
		
//		private static const COLOR_NORMAL: uint = 0x00CCFF;
		private static const COLOR_NORMAL: uint = 0xFFFFFF;
		private static const COLOR_MIN: uint = 0x99FF00;
		private static const COLOR_MAX: uint = 0xF60094;
		private static const GRAPH_THICKNESS: uint = 1;
		
		private static const MEMORY_MAX_VALUES: uint = 78;		
		//
	    // instances
	    private var _dataTxt : TextField;
	    private var _dataTxtFormat : TextFormat;
	    
		private var _bg : Sprite;
	    
		private var _bgGraphArea : Sprite;
	    private var _graph: Sprite;
	    private var _holderGraph: Sprite;
	    private var _bgGraph: Sprite;
	    private var _maskGraph: Sprite;
	    
	    private var _graphTimer : Timer;
	    
	    private var _memValues: Array;
	    
	    private var _b_start: Button;
	    private var _b_pause: Button;
	    
		/**
		* constructor
		*/
		public function WSMonitor()
		{
			createChildren();			
		}

		/**
		* Creates all child elements
		*/
		private function createChildren (): void 
		{

			//
			// backround
			_bg = new Sprite();
			_bg.graphics.beginFill(0, 1);
			_bg.graphics.drawRoundRect(0, 0, WIDTH, HEIGHT, 15, 15);
			_bg.graphics.endFill();
			addChild(_bg);	
			
			//
			// logo
			var logo: Logo = new Logo();
			logo.x = WIDTH - logo.width - 20;
			logo.y = 5;
			logo.addEventListener(MouseEvent.CLICK,
									function(even: MouseEvent): void
									{
										navigateToURL( new URLRequest("http://www.websector.de/blog/"));
									});
			logo.buttonMode = true;
			addChild(logo);	

			//
			// txtField for data
			_dataTxtFormat = new TextFormat();			
			_dataTxtFormat.font = FONT;
			_dataTxtFormat.color = 0xFFFFFF;
			_dataTxtFormat.size = 8;
		
			_dataTxt = new TextField();
			_dataTxt.embedFonts = true;	
			_dataTxt.multiline = true;
			_dataTxt.selectable = false;
			_dataTxt.autoSize = TextFieldAutoSize.LEFT;
			_dataTxt.defaultTextFormat = _dataTxtFormat;
			_dataTxt.x = 10;
			_dataTxt.y = 5;
			addChild(_dataTxt);			
				
			showTxtData();		
		

			//
			// backround of graph
			_bgGraphArea = new Sprite();
			_bgGraphArea.graphics.beginFill(0xFFFFFF, .1);
			_bgGraphArea.graphics.lineStyle(1, 0xFFFFFF);
			_bgGraphArea.graphics.drawRect(	-GRAPH_AREA_DIFF, 
											-GRAPH_AREA_DIFF, 
											GRAPH_AREA_WIDTH + GRAPH_AREA_DIFF, 
											GRAPH_AREA_HEIGHT + GRAPH_AREA_DIFF);
			_bgGraphArea.graphics.endFill();
			_bgGraphArea.x = 12;
			_bgGraphArea.y = _dataTxt.y + _dataTxt.height + 10;
		
			addChild(_bgGraphArea);
			
			//
			// graph holder
			_holderGraph = new Sprite();
			_bgGraphArea.addChild(_holderGraph);
					
			//
			// graph background
			_bgGraph = new Sprite();
			_bgGraph.y = GRAPH_AREA_HEIGHT;
			_holderGraph.addChild(_bgGraph);
			//
			// graph sprite
			_graph = new Sprite();
			_graph.y = GRAPH_AREA_HEIGHT;
			_holderGraph.addChild(_graph);
			
			//
			//
			var dropShadow: DropShadowFilter = new DropShadowFilter();
			dropShadow.blurX = 2;
			dropShadow.blurY = 2;
			dropShadow.distance = 2;
			dropShadow.angle = 135;
			dropShadow.quality = 1;
			dropShadow.alpha = 0.85;
			dropShadow.color = 0;
			
			_graph.filters = [dropShadow];

						
			//
			// mask graph and its bg
			_maskGraph = new Sprite();
			_maskGraph.graphics.beginFill(0xFFFFFF, .1);
			_maskGraph.graphics.drawRect(0, 0, GRAPH_AREA_WIDTH, GRAPH_AREA_HEIGHT);
			_maskGraph.graphics.endFill();
			
			_holderGraph.addChild(_maskGraph);
			_holderGraph.mask = _maskGraph;	
						
			//
			// timer
			_graphTimer = new Timer(80, 0);
			_graphTimer.addEventListener(TimerEvent.TIMER, graphTimerHandler);
			
			//
			// store mem values
			_memValues = new Array();	

			//
			// txtField for data
			var _disabledTxtFormat: TextFormat = new TextFormat();			
			_disabledTxtFormat.font = FONT;
			_disabledTxtFormat.color = 0x999999;
			_disabledTxtFormat.size = 8;
						
			_b_start = new Button();
			_b_start.x = 10;
			_b_start.y = _bgGraphArea.y + _bgGraphArea.height + 5;
			_b_start.width = 55;
			_b_start.height = 30;
			_b_start.toggle = true;
			_b_start.setStyle("textFormat", _dataTxtFormat);
			_b_start.setStyle("disabledTextFormat", _disabledTxtFormat);
			_b_start.setStyle("embedFonts", true);			
			_b_start.label = "start";	
			_b_start.addEventListener(MouseEvent.CLICK, onClickStartButton);
			addChild(_b_start);

			_b_pause = new Button();
			_b_pause.x = _b_start.x + _b_start.width + 10;
			_b_pause.y = _b_start.y;
			_b_pause.width = 55;
			_b_pause.height = 30;
			_b_pause.toggle = true;
			_b_pause.setStyle("textFormat", _dataTxtFormat);
			_b_pause.setStyle("embedFonts", true);
			_b_pause.setStyle("disabledTextFormat", _disabledTxtFormat);
			_b_pause.label = "pause";
			_b_pause.enabled = false;
			_b_pause.addEventListener(MouseEvent.CLICK, onClickPauseButton);
						
			addChild(_b_pause);			

			var _playerInfoTxt: TextField = new TextField();
			_playerInfoTxt.embedFonts = true;	
			_playerInfoTxt.selectable = false;
			_playerInfoTxt.defaultTextFormat = _dataTxtFormat;
			_playerInfoTxt.y = _b_start.y + 7;
			_playerInfoTxt.autoSize = TextFieldAutoSize.LEFT;
			_playerInfoTxt.htmlText = "<font color='#666666'>flash player: " + Capabilities.version + "</font>";
			_playerInfoTxt.x = WIDTH - _playerInfoTxt.width - 20;
			addChild(_playerInfoTxt);	
			
		};

		/**
		* Shows memory data
		* 
		*/		
		private function showTxtData (): void 
		{
			_dataTxt.htmlText = "memory usage: <font color='#00CCFF'>" + calculateMB(_memCurrentValue) + " MB (" + calculateKB(_memCurrentValue) + " kb) </font>";
			_dataTxt.htmlText += "memory min: <font color='#99FF00'>" + calculateMB(_memMinValue) + " MB (" + calculateKB(_memMinValue) + " kb) </font>";
			_dataTxt.htmlText += "memory max: <font color='#F60094'>" + calculateMB(_memMaxValue) + " MB (" + calculateKB(_memMaxValue) + " kb) </font>";
		};

		/**
		* Draws a graph using memory data
		* 
		*/		
		private function drawGraph (): void 
		{
					
				// clear graph and its background
				_graph.graphics.clear();
				_bgGraph.graphics.clear();

				var color: uint = getGraphColor(_memCurrentValue, _memLastValue);
				var yPos: uint = getGraphPosY(_memValues[0]);
									
				_graph.graphics.lineStyle(GRAPH_THICKNESS, color);		
				_graph.graphics.moveTo(0, -yPos);	
				
				var i: int;
				var l: int = _memValues.length;
				for(i=0; i <l; i++)
				{			
					color = getGraphColor(_memValues[i], _memValues[i-1]);
					yPos = getGraphPosY(_memValues[i]);
					
					with (_graph.graphics)
					{
						lineStyle(GRAPH_THICKNESS, color);
						
						lineTo(i * 4, 0-yPos);					
					}
					
					
					with (_bgGraph.graphics)
					{
						beginFill(color, .65);
						moveTo( i * 4, -yPos);
						lineTo( i * 4, 0);
						lineTo( (i-1) * 4, 0);
						lineTo( (i-1) * 4, -getGraphPosY(_memValues[i-1]));
						lineTo( i * 4, -yPos);
						endFill();
					}
				}
				
		};

		/**
		* Clears all data
		* 
		*/		
		private function resetData (): void 
		{
			_graph.graphics.clear();
			_bgGraph.graphics.clear();
			
			_memValues.length 
			= _memCurrentValue 
			= _memLastValue 
			= _memMinValue 
			= _memMaxValue 
			= 0;
			
			_firstRun = true;
					
		};
		
		///////////////////////////////////////////////////////////
		// user input handling
		///////////////////////////////////////////////////////////		

		/**
		* Callback method clicking start button
		* @param	event 	MouseEvent
		*/		
		private function onClickStartButton (event : MouseEvent): void 
		{
			
			if(_b_start.selected)
			{
				_b_start.label = "stop";
				_b_pause.label = "pause";
				_b_pause.selected = false;
				_b_pause.enabled = true;
				start();
			}
			else
			{
				_b_start.label = "start";
				_b_pause.label = "resume";
				_b_pause.enabled = false;
				stop();
			}
		};

		/**
		* Callback method clicking pause button
		* @param	event	MouseEvent
		*/
		private function onClickPauseButton (event : MouseEvent): void 
		{			
			if(_b_pause.selected)
			{
				_b_pause.label = "resume";
				pause();
			}
			else
			{
				_b_pause.label = "pause";
				resume();
			}
		};

		/**
		* Starts app using Timer
		* 
		*/				
		private function start () : void 
		{
			_graphTimer.start();			
		};
		
		/**
		* Stops app
		* 
		*/			
		private function stop (): void 
		{
			_graphTimer.stop();
			resetData();
			showTxtData();
		};
		
		/**
		* Pauses app
		* 
		*/	
		private function pause (): void 
		{
			_graphTimer.stop();
		};

		/**
		* Restarts app using Timer
		* 
		*/			
		private function resume (): void 
		{
			_graphTimer.start();
		};

		/**
		* Callback for running graphTimer
		* @param	event	TimerEvent dispatching by graphTimer
		*/			
		private function graphTimerHandler (event : TimerEvent) : void 
		{
			_memLastValue = _memCurrentValue;
			_memCurrentValue = System.totalMemory;
			
			if (_firstRun) 
			{
				_memMinValue = _memCurrentValue;
				_firstRun = false;
			}
			
			_memValues.push(_memCurrentValue);
			
			if (_memValues.length > MEMORY_MAX_VALUES) _memValues.splice(0, 1);
			//
			// copy _memValues to calculate min and max values
			var _memValuesCopy: Array = _memValues.slice();
			_memValuesCopy.sort(Array.NUMERIC);
			// min
			var min: uint = _memValuesCopy[0];
			_memMinValue = (_memMinValue > min) ? min : _memMinValue;
			// max			
			var max: uint = _memValuesCopy[_memValuesCopy.length - 1];
			_memMaxValue = (_memMaxValue < max) ? max : _memMaxValue;
			
			showTxtData();
			
			drawGraph();
			
		};
		
		///////////////////////////////////////////////////////////
		// helper methods
		///////////////////////////////////////////////////////////

		/**
		* Getting the right color for the graph depending on memory data
		* @param	value1		current value using memoryTotal
		* @param	value2		value before using memoryTotal
		* @return	value of color
		*/
		private function getGraphColor (value1: int, value2:int): uint 
		{
			var color: uint;
			
			if (value1 > value2)
			{
				color = COLOR_MAX;
			}
			else if (value1 < value2)
			{
				color = COLOR_MIN;
			}
			else
			{
			 	color = COLOR_NORMAL;
			}
			
			return color;			
		};

		/**
		* Getting the graph y-position depending on the latest memory value
		* @param	value		current value using memoryTotal
		* @return	value of rounded y-position 
		*/		
		private function getGraphPosY (value: int): uint 
		{
			return Math.round(GRAPH_AREA_HEIGHT * (value - _memMinValue) / (_memMaxValue - _memMinValue));
		};

		/**
		* Convert a value of byte in a value in kb
		* @param	value		current value using memoryTotal
		* @return	value in kb
		* 
		*/					
		private function calculateKB(value: uint): uint 
        {
            return Math.round(value / 1024);
        }

		/**
		* Convert a value of byte in a value in megabyte
		* @param	value		current value using memoryTotal
		* @return	value in MB
		* 
		*/
        private function calculateMB(value: uint): Number 
        {
            // calculate MB rounding with two digits
            var newValue: Number = Math.round(value / 1024 / 1024 * 100);          
            return newValue / 100;
        }
		

		///////////////////////////////////////////////////////////
		// toString
		///////////////////////////////////////////////////////////
		
		override public function toString() : String 
	    {
		    return "[Instance of:  de.websector.util.tools.WSProfiler]";
	    }
	}
}