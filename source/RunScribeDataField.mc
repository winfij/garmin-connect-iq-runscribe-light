//
// MIT License
//
// Copyright (c) 2017 Scribe Labs Inc
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

using Toybox.WatchUi as Ui;
using Toybox.Application as App;
using Toybox.Graphics as Gfx;
using Toybox.FitContributor as Fit;

class RunScribeDataField extends Ui.DataField {
    
    hidden var mMetric1Type; // 1 - Impact GS, 2 - Braking GS, 3 - FS Type, 4 - Pronation, 5 - Flight Ratio, 6 - Contact Time
    hidden var mMetric2Type; // 1 - Impact GS, 2 - Braking GS, 3 - FS Type, 4 - Pronation, 5 - Flight Ratio, 6 - Contact Time
    hidden var mMetric3Type; // 0 - None, 1 - Impact GS, 2 - Braking GS, 3 - FS Type, 4 - Pronation, 5 - Flight Ratio, 6 - Contact Time
    hidden var mMetric4Type; // 0 - None, 1 - Impact GS, 2 - Braking GS, 3 - FS Type, 4 - Pronation, 5 - Flight Ratio, 6 - Contact Time

    hidden var mMetricCount;
    hidden var mVisibleMetricCount;

    // Common
    hidden var mMetricTitleY;
    hidden var mMetricValueY;
    hidden var mMetricValueOffsetX;
        
    // Font values
    hidden var mDataFont;
    hidden var mDataFontHeight;
    
    var mSensorLeft;
    var mSensorRight;
    
    hidden var mScreenShape;
    hidden var mScreenHeight;
    
    hidden var xCenter;
    hidden var yCenter;
    
    hidden var mUpdateLayout = 0;
    
    // FIT Contributions variables
    hidden var mCurrentBGFieldLeft;
    hidden var mCurrentIGFieldLeft;
    hidden var mCurrentFSFieldLeft;
    hidden var mCurrentPronationFieldLeft;
    hidden var mCurrentFlightFieldLeft;
    hidden var mCurrentGCTFieldLeft;

    hidden var mCurrentBGFieldRight;
    hidden var mCurrentIGFieldRight;
    hidden var mCurrentFSFieldRight;
    hidden var mCurrentPronationFieldRight;
    hidden var mCurrentFlightFieldRight;
    hidden var mCurrentGCTFieldRight;    

    hidden var mCurrentPowerField;
    
    hidden var mMesgPeriod;
    
    // Constructor
    function initialize(screenShape, screenHeight, storedChannelCount) {
        DataField.initialize();
        
        mScreenShape = screenShape;
        mScreenHeight = screenHeight;
        
        onSettingsChanged();        

        var d = {};
        var units = "units";

        var offset = 0;

        if (storedChannelCount == 2) {
	        mCurrentFSFieldRight = createField("FS_R", 8, Fit.DATA_TYPE_SINT8, d);
	        mCurrentFSFieldLeft = createField("FS_L", 2 + offset, Fit.DATA_TYPE_SINT8, d);
        } else {
            offset = 12;
	        mCurrentFSFieldLeft = createField("FS", 2 + offset, Fit.DATA_TYPE_SINT8, d);
        }	        

        d[units] = "G";       
        if (storedChannelCount == 2) {         
	        mCurrentBGFieldRight = createField("BrakingGs_R", 6, Fit.DATA_TYPE_FLOAT, d);
	        mCurrentIGFieldRight = createField("ImpactGs_R", 7, Fit.DATA_TYPE_FLOAT, d);
	        mCurrentBGFieldLeft = createField("BrakingGs_L", 0 + offset, Fit.DATA_TYPE_FLOAT, d);
    	    mCurrentIGFieldLeft = createField("ImpactGs_L", 1 + offset, Fit.DATA_TYPE_FLOAT, d);
        } else {
	        mCurrentBGFieldLeft = createField("BrakingGs", 0 + offset, Fit.DATA_TYPE_FLOAT, d);
    	    mCurrentIGFieldLeft = createField("ImpactGs", 1 + offset, Fit.DATA_TYPE_FLOAT, d);
        }	
        
        d[units] = "°";        
        if (storedChannelCount == 2) {         
	        mCurrentPronationFieldRight = createField("Pronation_R", 9, Fit.DATA_TYPE_SINT16, d);
	        mCurrentPronationFieldLeft = createField("Pronation_L", 3 + offset, Fit.DATA_TYPE_SINT16, d);
        } else {
	        mCurrentPronationFieldLeft = createField("Pronation", 3 + offset, Fit.DATA_TYPE_SINT16, d);
        }
	    
	    d[units] = "%";
	    if (storedChannelCount == 2) {
	        mCurrentFlightFieldRight = createField("FlightRatio_R", 10, Fit.DATA_TYPE_SINT8, d);
	        mCurrentFlightFieldLeft = createField("FlightRatio_L", 4 + offset, Fit.DATA_TYPE_SINT8, d);
		} else {
	        mCurrentFlightFieldLeft = createField("FlightRatio", 4 + offset, Fit.DATA_TYPE_SINT8, d);
		}
	   
	    d[units] = "ms";
        if (storedChannelCount == 2) {
	        mCurrentGCTFieldRight = createField("ContactTime_R", 11, Fit.DATA_TYPE_SINT16, d);
	        mCurrentGCTFieldLeft = createField("ContactTime_L", 5 + offset, Fit.DATA_TYPE_SINT16, d);
        } else {
	        mCurrentGCTFieldLeft = createField("ContactTime", 5 + offset, Fit.DATA_TYPE_SINT16, d);
        }
        
        d[units] = "W";
        mCurrentPowerField = createField("Power", 18, Fit.DATA_TYPE_SINT16, d);
    }
    
    function onSettingsChanged() {
        var app = App.getApp();
        
        var antRate = app.getProperty("antRate");
        mMesgPeriod = 8192/Math.pow(2, antRate);        
        
        var name = "typeMetric";
        mMetric1Type = app.getProperty(name + "1");
        mMetric2Type = app.getProperty(name + "2");
        mMetric3Type = app.getProperty(name + "3");
        mMetric4Type = app.getProperty(name + "4");

        // Remove empty metrics from between
        if (mMetric2Type == 0) {
            if (mMetric3Type == 0) {
                mMetric2Type = mMetric4Type;
                mMetric4Type = 0;
            } else {
                mMetric2Type = mMetric3Type;
                mMetric3Type = mMetric4Type;
                mMetric4Type = 0;
            }
        } else if (mMetric3Type == 0) {
            mMetric3Type = mMetric4Type;
            mMetric4Type = 0;
        }
        
        if (mMetric4Type != 0) {
            mMetricCount = 4; 
        } else if (mMetric3Type != 0) {
            mMetricCount = 3;
        } else if (mMetric2Type != 0) {
            mMetricCount = 2;
        } else {
            mMetricCount = 1;
        }
        
        mUpdateLayout = 1;
    }
    
    // If L/R recording is enabled, store values in appropriate result.
    // If L/R recording is disabled and both left and right are valid, store the average in left result.
    // If L/R recording is disabled but only one value is valid, store that in the left result.
    function storeValues(leftValid, rightValid, leftValue, rightValue, resultFieldLeft, resultFieldRight) {
    	if (mCurrentBGFieldRight != null) {
/*	    	System.print("Stored leftValue:");
	    	System.print(leftValue);
	    	System.print(" rightValue:");
	    	System.println(rightValue);*/
    		resultFieldLeft.setData(leftValue);
    		resultFieldRight.setData(rightValue);
    	}
    	else if (leftValid && rightValid) {
    		resultFieldLeft.setData((leftValue + rightValue) / 2);
/*	    	System.print("Stored avgValue:");
	    	System.println((leftValue + rightValue) / 2);*/
    	}
    	else
    	{
    		resultFieldLeft.setData(leftValid?leftValue:(rightValid?rightValue:0));
/*	    	System.print("Stored single value:");
	    	System.println(leftValid?leftValue:(rightValid?rightValue:0));*/
    	}
    }

    function compute(info) {
    	// Elem[0]=left Elem[1]=right
        var braking = new[2];
        var impact = new[2];
        var footstrike = new[2];
        var pronation = new[2];
        var flight = new[2];
        var contact = new[2];
        var power = new[2];
    	var leftValid = false;
    	var rightValid = false;
    
        if (mSensorLeft == null || !mSensorLeft.isChannelOpen) {
            mSensorLeft = null;
            try {
                mSensorLeft = new RunScribeSensor(11, 62, mMesgPeriod);
            } catch(e instanceof Ant.UnableToAcquireChannelException) {
                mSensorLeft = null;
            }
        } else {

            ++mSensorLeft.idleTime;
			if (mSensorLeft.idleTime > 8) {
    				mSensorLeft.closeChannel();
			}
			if (!mSensorLeft.searching) {
	            braking[0] = mSensorLeft.braking_gs;
	            impact[0] = mSensorLeft.impact_gs;
	            footstrike[0] = mSensorLeft.footstrike_type;
	            pronation[0] = mSensorLeft.pronation_excursion_fs_mp;
	            flight[0] = mSensorLeft.flight_ratio;
	            contact[0] = mSensorLeft.contact_time;
	            power[0] = mSensorLeft.power;
	            leftValid = true;
			}
        }
        
        if (mSensorRight == null || !mSensorRight.isChannelOpen) {
            mSensorRight = null;
            try {
                mSensorRight = new RunScribeSensor(12, 64, mMesgPeriod);
            } catch(e instanceof Ant.UnableToAcquireChannelException) {
                mSensorRight = null;
            }
        } else {

            ++mSensorRight.idleTime;
			if (mSensorRight.idleTime > 8) {
    				mSensorRight.closeChannel();
    		}
			if (!mSensorRight.searching) {
	            braking[1] = mSensorRight.braking_gs;
	            impact[1] = mSensorRight.impact_gs;
	            footstrike[1] = mSensorRight.footstrike_type;
	            pronation[1] = mSensorRight.pronation_excursion_fs_mp;
	            flight[1] = mSensorRight.flight_ratio;
	            contact[1] = mSensorRight.contact_time;
	            power[1] = mSensorRight.power;
	            rightValid = true;
			}
        }

		// Store the computed results to the Connect datafields
	    storeValues(leftValid, rightValid, braking[0], braking[1], mCurrentBGFieldLeft, mCurrentBGFieldRight);
	    storeValues(leftValid, rightValid, impact[0], impact[1], mCurrentIGFieldLeft, mCurrentIGFieldRight);
	    storeValues(leftValid, rightValid, footstrike[0], footstrike[1], mCurrentFSFieldLeft, mCurrentFSFieldRight);
	    storeValues(leftValid, rightValid, pronation[0], pronation[1], mCurrentPronationFieldLeft, mCurrentPronationFieldRight);
	    storeValues(leftValid, rightValid, flight[0], flight[1], mCurrentFlightFieldLeft, mCurrentFlightFieldRight);
	    storeValues(leftValid, rightValid, contact[0], contact[1], mCurrentGCTFieldLeft, mCurrentGCTFieldRight);

		// Treat power differently, only ever record a single value
		if (leftValid && rightValid) {
			// Store the average
    		mCurrentPowerField.setData((power[0] + power[1]) / 2);
		}
		else {
			// Pick the valid value, or use 0
    		mCurrentPowerField.setData(leftValid?power[0]:(rightValid?power[1]:0));
		}
    }

    function onLayout(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        if (height < mScreenHeight) {
            mVisibleMetricCount = 1;
        } else {
            mVisibleMetricCount = mMetricCount;
        }
        
        xCenter = width / 2;
        yCenter = height / 2;
                
        mMetricValueOffsetX = dc.getTextWidthInPixels(" ", Gfx.FONT_XTINY) + 2;

        // Compute data width/height for horizintal layouts
        var metricNameFontHeight = dc.getFontHeight(Gfx.FONT_XTINY) + 2;
        if (mVisibleMetricCount == 2) {
            width *= 1.6;
        } else if (mVisibleMetricCount == 1) {
            width *= 2.0;
        }

        mDataFont = selectFont(dc, width * 0.45, height - metricNameFontHeight, "00.0--00.0");
            
        mDataFontHeight = dc.getFontHeight(mDataFont);    
            
        mMetricTitleY = -(mDataFontHeight + metricNameFontHeight) * 0.5;
        if (mScreenShape == System.SCREEN_SHAPE_ROUND) {
            mMetricTitleY *= 1.1;
        } 
        
        mMetricValueY = mMetricTitleY + metricNameFontHeight;
        
        mUpdateLayout = 0;
    }
    
    hidden function selectFont(dc, width, height, testString) {
        var fontIdx;
        var dimensions;
        
        var fonts = [Gfx.FONT_XTINY, Gfx.FONT_TINY, Gfx.FONT_SMALL, Gfx.FONT_MEDIUM, Gfx.FONT_LARGE,
                    Gfx.FONT_NUMBER_MILD, Gfx.FONT_NUMBER_MEDIUM, Gfx.FONT_NUMBER_HOT, Gfx.FONT_NUMBER_THAI_HOT];
                     
        //Search through fonts from biggest to smallest
        for (fontIdx = fonts.size() - 1; fontIdx > 0; --fontIdx) {
            dimensions = dc.getTextDimensions(testString, fonts[fontIdx]);
            if ((dimensions[0] <= width) && (dimensions[1] <= height)) {
                // If this font fits, it is the biggest one that does
                break;
            }
        }
        
        return fonts[fontIdx];
    }
    
    hidden function getMetricName(metricType) {
    	switch (metricType) {
            case 1 : {
	            return "Impact Gs";
            } 
            case 2 : {
    	        return "Braking Gs";
            } 
            case 3 : {
	            return "Footstrike";
            } 
            case 4 : {
	            return "Pronation";
            } 
            case 5 : {
	            return "Flight (%)";
            } 
            case 6 : {
	            return "GCT (ms)";
            } 
            case 7 : {
	            return "Power (W)";
            } 
        }
        
        return null;
    }
        
    hidden function getMetric(metricType, sensor) {
        var floatFormat = "%.1f";
        if (sensor != null) {
        	switch (metricType) {
	            case 1 : {
	                return sensor.impact_gs.format(floatFormat);
	            } 
	            case 2 : {
	                return sensor.braking_gs.format(floatFormat);
	            } 
	            case 3 : {
	                return sensor.footstrike_type.format("%d");
	            } 
	            case 4 : {
	                return sensor.pronation_excursion_fs_mp.format(floatFormat);
	            } 
	            case 5 : {
	                return sensor.flight_ratio.format(floatFormat);
	            } 
	            case 6 : {
	                return sensor.contact_time.format("%d");
	            }
	            case 7 : {
	                return sensor.power.format("%d");
	            }
	        }
        }
        return "0";
    }
    
    
    // Handle the update event
    function onUpdate(dc) {
        var bgColor = getBackgroundColor();
        var fgColor = Gfx.COLOR_WHITE;
        
        if (bgColor == Gfx.COLOR_WHITE) {
            fgColor = Gfx.COLOR_BLACK;
        }
        
        dc.setColor(fgColor, bgColor);
        dc.clear();
        
        dc.setColor(fgColor, Gfx.COLOR_TRANSPARENT);
        
        if (mUpdateLayout != 0) {
            onLayout(dc);
        }

        // Update status
        if (mSensorLeft != null && mSensorRight != null && (!mSensorRight.searching || !mSensorLeft.searching)) {
            
            var met1x, met1y, met2x = 0, met2y = 0, met3x = 0, met3y = 0, met4x = 0, met4y = 0;
            
            var yOffset = yCenter * 0.55;
            var xOffset = xCenter * 0.45;
        
            if (mScreenShape == System.SCREEN_SHAPE_SEMI_ROUND) {
                yOffset *= 1.15;
            }
        
            if (mVisibleMetricCount == 1) {
                met1x = xCenter;
                met1y = yCenter;
            }
            else if (mVisibleMetricCount == 2) {
                met1x = xCenter;
                met2x = met1x;
                if (mScreenShape == System.SCREEN_SHAPE_RECTANGLE) {
                    yOffset *= 1.35;
                }
                met1y = yCenter - yOffset * 0.6;
                met2y = yCenter + yOffset * 0.6;
            } else if (mScreenShape == System.SCREEN_SHAPE_RECTANGLE) {
                yOffset *= 0.8;
                met1x = xCenter - xOffset;
                met1y = yCenter - yOffset;
                met2x = xCenter + xOffset;
                met2y = met1y;
            
                if (mVisibleMetricCount == 3) {
                    met3x = xCenter;
                    met3y = yCenter + yOffset;  
                } else {
                    met3x = met1x;
                    met3y = yCenter + yOffset;  
                    met4x = met2x;
                    met4y = met3y;  
                }
            }
            else {
                met1x = xCenter;
                met1y = yCenter - yOffset;
                met2y = yCenter;
                 
                if (mVisibleMetricCount == 3) {
                    met2x = met1x;
                    met3x = met1x;
                    met3y = yCenter + yOffset;
                } else {
                    met2x = xCenter - xOffset;
                    met3x = xCenter + xOffset;
                    met3y = met2y;
                    met4x = met1x;
                    met4y = yCenter + yOffset;
                }
            }
            
            drawMetricOffset(dc, met1x, met1y, mMetric1Type);         
            if (mVisibleMetricCount >= 2) {
                drawMetricOffset(dc, met2x, met2y, mMetric2Type);
	            if (mVisibleMetricCount >= 3) {
	                drawMetricOffset(dc, met3x, met3y, mMetric3Type);
		            if (mVisibleMetricCount == 4) {
		                drawMetricOffset(dc, met4x, met4y, mMetric4Type);
		            } 
	            } 
            }
        } else {
            var message = "Searching(1.27)...";
            if (mSensorLeft == null || mSensorRight == null) {
                message = "No Channel!";
            }
            
            dc.drawText(xCenter, yCenter - dc.getFontHeight(Gfx.FONT_MEDIUM) / 2, Gfx.FONT_MEDIUM, message, Gfx.TEXT_JUSTIFY_CENTER);
        }        
    }

    hidden function drawMetricOffset(dc, x, y, metricType) {
    
        var metricLeft = getMetric(metricType, mSensorLeft);
        var metricRight = getMetric(metricType, mSensorRight);
        
        if (metricType == 7) {
            metricLeft = ((mSensorLeft.power + mSensorRight.power) / 2).format("%d");
        }
         
        dc.drawText(x, y + mMetricTitleY, Gfx.FONT_XTINY, getMetricName(metricType), Gfx.TEXT_JUSTIFY_CENTER);

        if (metricType == 7) {
            // Power metric presents a single value
            dc.drawText(x, y + mMetricValueY, mDataFont, metricLeft, Gfx.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(x - mMetricValueOffsetX, y + mMetricValueY, mDataFont, metricLeft, Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText(x + mMetricValueOffsetX, y + mMetricValueY, mDataFont, metricRight, Gfx.TEXT_JUSTIFY_LEFT);
            
            // Draw line
            dc.drawLine(x, y + mMetricValueY, x, y + mMetricValueY + mDataFontHeight);
        }    
    }
}
