using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.System as Sys;
using Toybox.Communications as Comm;


//---------------------------------------------------------
//---------------------------------------------------------
class TestWebRequestView extends Ui.View 
{
    const ClrWhite = 0xFFFFFF;//Gfx.COLOR_WHITE;
    const ClrBlack = 0x000000;//Gfx.COLOR_BLACK;
    enum {F0, F1, F2, F3, F4,FN0, FN1, FN2, FN3, FX1, FX2} //fonts
    enum {JR, JC, JL, JVC=4, JCC=5, JCORE=7 } //justify

    var tmRequest = null;       //what was the time of the last request - null=no request pending
    var strLastSuccess = "--";  //what time did wwe last get a successful response
    var tmStart;                //what time did we start the app
    var cRequest = 0;           //how many requests have been made
    var cErr = 0;               //how many error responses have we had
    
    //---------------------------------
    function initialize() 
    {
        tmStart = Sys.getTimer();
        View.initialize();
    }

    //---------------------------------
    function onTimerTic() //every second
    {
        //make a request if we don't have one pending
        if (tmRequest == null)
        {
            makeRequest();
        }
        Ui.requestUpdate(); //update the display regardless
    }
    
    //---------------------------------
    // Receive the data from the web request
    var strMsg;
    function onReceive(responseCode, data) 
    {
        //Sys.println("OnReceive");
        if (responseCode == 200) 
        {
            if (data instanceof Lang.String) 
            {
                //Sys.println("string");
                strMsg = data;
            }
            else if (data instanceof Dictionary) 
            {
                //Sys.println("dict");
                // Print the arguments duplicated and returned by jsonplaceholder.typicode.com
                var keys = data.keys();
                strMsg = "";
                for( var i = 0; i < keys.size(); i++ ) 
                {
                    strMsg += Lang.format("$1$: $2$\n", [keys[i], data[keys[i]]]);
                }
            }
            tmRequest = null;
            strLastSuccess = strTimeOfDay(false);
            //Sys.println(strMsg);
            Ui.requestUpdate();
        }
        else
        {
            cErr++;
            tmRequest = null;
        }
    }

    //---------------------------------
    function makeRequest() 
    {
        //don't bother making the request if there is no phone connected
        if (Sys.getDeviceSettings().phoneConnected)
        {
            //Sys.println("MakeRequest");
            tmRequest = Sys.getTimer();
            cRequest++;
            
            Comm.makeWebRequest(
                "https://jsonplaceholder.typicode.com/todos/115",
                {},
                {"Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED},
                method(:onReceive));
        }
    }

    //---------------------------------
    //  display Lines
    //     Duration since app started
    //     count of requests
    //     count of errors, current memory usage in k
    //     DurPend is time since the last request
    //     current clock time - time of last successful response
    //
    function onUpdate(dc) 
    {
        var xCenter = dc.getWidth() / 2;
        var y = 0;
        var fnt = F4;
        var cyLine = dc.getFontHeight(fnt) - 6; //text line spacing

        dc.setColor(ClrWhite, ClrBlack);
        dc.clear();
        
        y += cyLine/4;
        dc.drawText(xCenter, y, fnt, strDur(Sys.getTimer() - tmStart), JC);
        y += cyLine;
        dc.drawText(xCenter, y, fnt, "cReq=" + cRequest, JC);
        y += cyLine;
        dc.drawText(xCenter, y, fnt, "cErr=" + cErr + ", m=" + (Sys.getSystemStats().usedMemory/1024) + "k", JC);
        y += cyLine;
        dc.drawText(xCenter, y, fnt, "DurPend=" + 
          ((tmRequest != null) ? strDur(Sys.getTimer() - tmRequest) : "0:00"), JC);
        y += cyLine;
        dc.drawText(xCenter, y, fnt, strTimeOfDay(true) + " - " + strLastSuccess, JC);
        y += cyLine;
    }
}
