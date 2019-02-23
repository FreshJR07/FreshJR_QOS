<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<!-- 
##FreshJR_QOS_v8 released 02/01/2019
Modification on-top of RMerlins QoS_Stats page taken from 384.9
 -->
<html xmlns="http://www.w3.org/1999/xhtml">
<html xmlns:v>
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta HTTP-EQUIV="Pragma" CONTENT="no-cache">
<meta HTTP-EQUIV="Expires" CONTENT="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title><#705#> - Classification</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<link rel="stylesheet" type="text/css" href="usp_style.css">
<link rel="stylesheet" type="text/css" href="/js/table/table.css">
<script type="text/javascript" src="/js/jquery.js"></script>
<script type="text/javascript" src="/js/chart.min.js"></script>
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/js/table/table.js"></script>
<script type="text/javascript" src="js/httpApi.js"></script>
<style>

.tableApi_table th {
height: 22px;
text-align: left;
}
.tableApi_table td {
text-align: left;
}
.data_tr {
height: 32px;
}
span.cat0{
background-color:#B3645B;
}
span.cat1{
background-color:#B98F53;
}
span.cat2{
background-color:#C6B36A;
}
span.cat3{
background-color:#849E75;
}
span.cat4{
background-color:#4C8FC0;
}
span.cat5{
background-color:#7C637A;
}
span.cat6{
background-color:#2B6692;
}
span.cat7{
background-color:#6C604F;
}
span.catrow{
padding: 4px 8px 4px 8px; color: white !important;
border-radius: 5px; border: 1px #2f3a3e solid;
white-space: nowrap;
}


div.t_item{
cursor:default;
}
span.t_mark{
display:none;
}

div.t_item:active span.t_label{
display:none;
}
div.t_item:active span.t_mark{
display:inline;
}


div.localdeviceip{
display:inline-block; 
width:50%; 
}
span.devicename{
display:inline-block; 
font-size:75%;
width:50%;
vertical-align: middle;
white-space: nowrap;
overflow: hidden;
text-overflow: ellipsis;
}

</style>
<script>

var device = {};													// devices database --> device["IP"] = { mac: "AA:BB:CC:DD:EE:FF" , name:"name" }
var clientlist = <% get_clientlist_from_json_database(); %>;		// data from /jffs/nmp_cl_json.js (used to correlate mac addresses to corresponding device names  )
var tablesize = 500;						//max size of tracked connections table
var tabledata;								//tabled of tracked connections after device-filtered
var sortmode=6;								//current sort mode of tracked connections table (default =6)
var appdb1;				// AppDB rules
var appdb2;
var appdb3;
var appdb4;
var rule1;				// IPv4 rules
var rule2;
var rule3;
var rule4;
var gameCIDR;			// CIDR/IP of game devices
var ruleFLAG;			// Unused - reserved for toggling ON/OFF hardcoded rules in future release
//Syntax Hints
var ipsyntaxL = '<b>Syntax:</b> <p>&emsp;&nbsp;192.168.X.XXX</p> <p>&emsp;!192.168.X.XXX</p> <p>&nbsp;</p> <p>&emsp;&nbsp;192.168.X.XXX/CIDR</p> <p>&emsp;!192.168.X.XXX/CIDR</p>';
var ipsyntaxR = '<b>Syntax:</b> <p>&emsp;&nbsp;75.75.75.75</p> <p>&emsp;!75.75.75.75</p> <p>&nbsp;</p> <p>&emsp;&nbsp;75.75.75.75/CIDR</p> <p>&emsp;!75.75.75.75/CIDR</p>';
var protosyntax = '<b>Protocol</b> <p>&nbsp;&nbsp;TCP OR UDP</p> <p>&nbsp;</p> <b>Note:</b> <p>Conditional Evaluation</p> <p>(only with port rules)</p>' ;
var portsyntax = '<b>Syntax:</b> <p>&emsp;&nbsp;XXX</p> <p>&emsp;!XXX</p> <p>&nbsp;</p> <p>&emsp;&nbsp;XXXX:YYYY</p> <p>&emsp;!XXXX:YYYY</p> <p>&nbsp;</p> <p>&emsp;&nbsp;XXX,YYY,ZZZ</p> <p>&emsp;!XXX,YYY,ZZZ</p>';
var marksyntax = '<b>Syntax:</b> <p>&nbsp;&nbsp;XXYYYY</p> <p>&nbsp;</p> <p><b>Note:</b></p> <p>XX&nbsp;&nbsp;&nbsp; - Cat (hex)</p> <p>YYYY - ID &nbsp;(hex or ****)</p> ';
var classsyntax = '<b>Class:</b> <p>&nbsp;&nbsp;Traffic Destination</p>';


var qos_type = "<% nvram_get("qos_type"); %>";
if ("<% nvram_get("qos_enable"); %>" == 0) { // QoS disabled
    var qos_mode = 0;
} else if (bwdpi_support && (qos_type == "1")) { // aQoS
    var qos_mode = 2;
} else if (qos_type == "0") { // tQoS
    var qos_mode = 1;
} else if (qos_type == "2") { // BW limiter
    var qos_mode = 3;
} else { // invalid mode
    var qos_mode = 0;
}

if (qos_mode == 2) {
    var bwdpi_app_rulelist = "<% nvram_get("bwdpi_app_rulelist"); %>".replace(/&#60/g, "<");
    var bwdpi_app_rulelist_row = bwdpi_app_rulelist.split("<");
    if (bwdpi_app_rulelist == "" || bwdpi_app_rulelist_row.length != 9) {
        bwdpi_app_rulelist = "9,20<8<4<0,5,6,15,17<13,24<1,3,14<7,10,11,21,23<<";
        bwdpi_app_rulelist_row = bwdpi_app_rulelist.split("<");
    }
    var category_title = ["Net Control Packets", "<#752#>", "<#762#>", "<#756#>", "<#764#>", "<#751#>", "<#757#>", "Game Transferring"];
    var cat_id_array = [
        [9, 20],
        [8],
        [4],
        [0, 5, 6, 15, 17],
        [13, 24],
        [1, 3, 14],
        [7, 10, 11, 21, 23],
        []
    ];
	
	var c_net=bwdpi_app_rulelist_row.indexOf(cat_id_array[0].toString())
	var c_gaming=bwdpi_app_rulelist_row.indexOf(cat_id_array[1].toString())
	var c_streaming=bwdpi_app_rulelist_row.indexOf(cat_id_array[2].toString())
	var c_voip=bwdpi_app_rulelist_row.indexOf(cat_id_array[3].toString())
	var c_web=bwdpi_app_rulelist_row.indexOf(cat_id_array[4].toString())
	var c_downloads=bwdpi_app_rulelist_row.indexOf(cat_id_array[5].toString())
	var c_others=bwdpi_app_rulelist_row.indexOf(cat_id_array[6].toString())
	var c_default=bwdpi_app_rulelist_row.indexOf(cat_id_array[7].toString())
	
} else {
    var category_title = ["", "Highest", "High", "Medium", "Low", "Lowest"];
}
var pie_obj_ul, pie_obj_dl;
var refreshRate;
var timedEvent = 0;
var color = ["#B3645B", "#B98F53", "#C6B36A", "#849E75", "#4C8FC0",  "#7C637A", "#2B6692",  "#6C604F"];
<% get_tcclass_array(); %>;
<% bwdpi_conntrack(); %>;
var pieOptions = {
    segmentShowStroke: false,
    segmentStrokeColor: "#000",
    animationEasing: "easeOutQuart",
    animationSteps: 100,
    animateScale: true,
    legend: {
        display: false
    },
    tooltips: {
        callbacks: {
            title: function(tooltipItem, data) {
                return data.labels[tooltipItem[0].index];
            },
            label: function(tooltipItem, data) {
                var value = data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index];
                var orivalue = value;
                var total = eval(data.datasets[tooltipItem.datasetIndex].data.join("+"));
                var unit = " bytes";
                if (value > 1024) {
                    value = value / 1024;
                    unit = " KB";
                }
                if (value > 1024) {
                    value = value / 1024;
                    unit = " MB";
                }
                if (value > 1024) {
                    value = value / 1024;
                    unit = " GB";
                }
                return value.toFixed(2) + unit + ' ( ' + parseFloat(orivalue * 100 / total).toFixed(2) + '% )';
            },
        }
    },
}


function ip2dec(addr) {
  if( /\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b$/.test(addr) )		//regex that accepts ipv4 addresses ###.###.###.### (no cidr flag allowed)
  {
  	var parts = addr.split('.').map(Number);
  	return (parts[0] << 24) + (parts[1] << 16) + (parts[2] << 8) + (parts[3]) >>> 0;
  }
  else return 0
};

function cidr_start(addr) {
  addr=addr.split('/');
  var parts = addr[0].split('.').map(Number);
  var dec_ip = (parts[0] << 24) + (parts[1] << 16) + (parts[2] << 8) + (parts[3]) >>> 0;
	var dec_mask= (4294967295 << 32-addr[1]) >>> 0;	
  return (dec_ip&dec_mask)>>>0;
};

function cidr_end(addr) {
  addr=addr.split('/');
  var parts = addr[0].split('.').map(Number);
  var dec_ip = (parts[0] << 24) + (parts[1] << 16) + (parts[2] << 8) + (parts[3]) >>> 0;
	var dec_mask= ~(4294967295 << 32-addr[1]) >>> 0;	
  return (dec_ip|dec_mask)>>>0;
};


function draw_conntrack_table() {
	//bwdpi_conntrack[i][0] = protocol
	//bwdpi_conntrack[i][1] = Source IP
	//bwdpi_conntrack[i][2] = Source Port
	//bwdpi_conntrack[i][3] = Destination IP
	//bwdpi_conntrack[i][4] = Destination Port
	//bwdpi_conntrack[i][5] = Pre-formatted Title
	//bwdpi_conntrack[i][6] = Traffic ID
	//bwdpi_conntrack[i][7] = Traffic Category
	tabledata = new Array(tablesize);
	var j = 0;
    for (var i = 0; i < bwdpi_conntrack.length; i++) 
	{	
		if (( deviceFilter == "*" || deviceFilter == bwdpi_conntrack[i][1] ) && ( j < tablesize ))
		{
			//format app name label into html
			var label = bwdpi_conntrack[i][5];			(label.length > 27) ? size='style="font-size: 75%;"' : size = "" ;
			var qos_class = get_qos_class(bwdpi_conntrack[i][7], bwdpi_conntrack[i][6]);
			var mark = (parseInt(bwdpi_conntrack[i][7]).toString(16).padStart(2,'0') + parseInt(bwdpi_conntrack[i][6]).toString(16).padStart(4,'0')).toUpperCase();
			//bwdpi_conntrack[i][5] =  '<span title="' + label + '" class="catrow cat' + qos_class + '"' + size + '>' + label + '</span>';			//sort by AppID name
			bwdpi_conntrack[i][5] =	'<div  class="t_item">' +
									'<span class="t_label catrow cat' + qos_class + '"' + size + '>' + label + '</span>' +							//sort by Container Destination
									'<span class="t_mark  catrow cat' + qos_class + '"' + size + '>MARK:' + mark + '</span>' +
									'<div>';	
			
			//shorten IPV6
			var isIPv6 = false;
			if (bwdpi_conntrack[i][1].indexOf(":") >= 0) {
				bwdpi_conntrack[i][1] = compIPV6(bwdpi_conntrack[i][1]);
				isIPv6 = true;
			}
			if (bwdpi_conntrack[i][3].indexOf(":") >= 0) {
				bwdpi_conntrack[i][3] = compIPV6(bwdpi_conntrack[i][3]);
				isIPv6 = true;
			}
			
			
			//OVERRIDE LABEL - TC RULES
			if (bwdpi_conntrack[i][7] == 0 && bwdpi_conntrack[i][6] == 0 )																			//unidentified
				bwdpi_conntrack[i][5] =	'<div  class="t_item">' +
						'<span class="t_label catrow cat' + c_others + '"' + size + '>' + label + '</span>' +				
						'<span class="t_mark  catrow cat' + c_others + '"' + size + '>MARK:' + mark + '</span>' +
						'<div>';	
			
			if (bwdpi_conntrack[i][7] == 13 && (bwdpi_conntrack[i][6] == 7 || bwdpi_conntrack[i][6] == 134 || bwdpi_conntrack[i][6] == 160) )		//speedtest + playstore + appstore
				bwdpi_conntrack[i][5] =	'<div  class="t_item">' +
						'<span class="t_label catrow cat' + c_downloads + '"' + size + '>' + label + '</span>' +				
						'<span class="t_mark  catrow cat' + c_downloads + '"' + size + '>MARK:' + mark + '</span>' +
						'<div>';	
			
			if (bwdpi_conntrack[i][7] == 0 && bwdpi_conntrack[i][6] == 107) 																		//snapchat
				bwdpi_conntrack[i][5] =	'<div  class="t_item">' +
						'<span class="t_label catrow cat' + c_others + '"' + size + '>' + label + '</span>' +				
						'<span class="t_mark  catrow cat' + c_others + '"' + size + '>MARK:' + mark + '</span>' +
						'<div>';	
			
			if (bwdpi_conntrack[i][7] == 19 || bwdpi_conntrack[i][7] == 20 || (  bwdpi_conntrack[i][7] == 18 && bwdpi_conntrack[i][6]==63) )		//https + TSL/SSL + http
				bwdpi_conntrack[i][5] =	'<div  class="t_item">' +
						'<span class="t_label catrow cat' + c_web + '"' + size + '>' + label + '</span>' +				
						'<span class="t_mark  catrow cat' + c_web + '"' + size + '>MARK:' + mark + '</span>' +
						'<div>';	

			if (eval_rule(appdb1, bwdpi_conntrack[i][0], bwdpi_conntrack[i][2], bwdpi_conntrack[i][4], bwdpi_conntrack[i][1], bwdpi_conntrack[i][3], bwdpi_conntrack[i][7], bwdpi_conntrack[i][6]))
				bwdpi_conntrack[i][5] =	'<div  class="t_item">' +
						'<span class="t_label catrow cat' + appdb1[18] + '"' + size + '>' + label + ' ~</span>' +				
						'<span class="t_mark  catrow cat' + appdb1[18] + '"' + size + '>MARK:' + mark + '</span>' +
						'<div>';	
			
			if (eval_rule(appdb2, bwdpi_conntrack[i][0], bwdpi_conntrack[i][2], bwdpi_conntrack[i][4], bwdpi_conntrack[i][1], bwdpi_conntrack[i][3], bwdpi_conntrack[i][7], bwdpi_conntrack[i][6]))
				bwdpi_conntrack[i][5] =	'<div  class="t_item">' +
						'<span class="t_label catrow cat' + appdb2[18] + '"' + size + '>' + label + ' ~</span>' +					
						'<span class="t_mark  catrow cat' + appdb2[18] + '"' + size + '>MARK:' + mark + '</span>' +
						'<div>';	
			
			if (eval_rule(appdb3, bwdpi_conntrack[i][0], bwdpi_conntrack[i][2], bwdpi_conntrack[i][4], bwdpi_conntrack[i][1], bwdpi_conntrack[i][3], bwdpi_conntrack[i][7], bwdpi_conntrack[i][6]))
				bwdpi_conntrack[i][5] =	'<div  class="t_item">' +
						'<span class="t_label catrow cat' + appdb3[18] + '"' + size + '>' + label + ' ~</span>' +						
						'<span class="t_mark  catrow cat' + appdb3[18] + '"' + size + '>MARK:' + mark + '</span>' +
						'<div>';	
			
			if (eval_rule(appdb4, bwdpi_conntrack[i][0], bwdpi_conntrack[i][2], bwdpi_conntrack[i][4], bwdpi_conntrack[i][1], bwdpi_conntrack[i][3], bwdpi_conntrack[i][7], bwdpi_conntrack[i][6]))
				bwdpi_conntrack[i][5] =	'<div  class="t_item">' +
						'<span class="t_label catrow cat' + appdb3[18] + '"' + size  + '>' + label + ' ~</span>' +						
						'<span class="t_mark  catrow cat' + appdb3[18] + '"' + size + '>MARK:' + mark + '</span>' +
						'<div>';	

			
			if (!isIPv6)
			{
				//SHOW LOCAL DEVICES AT LEFT SIDE OF TABLE (FLIP POSITION IF REQUIRED)
				if (bwdpi_conntrack[i][3].startsWith("192.168.2."))
				{
					var temp = bwdpi_conntrack[i][3];
					bwdpi_conntrack[i][3] = bwdpi_conntrack[i][1];
					bwdpi_conntrack[i][1] = temp;
					
					temp = bwdpi_conntrack[i][4];
					bwdpi_conntrack[i][4] = bwdpi_conntrack[i][2];
					bwdpi_conntrack[i][2] = temp;
					
				}
				
				
				//OVERRIDE LABEL - IPTABLE RULES
				if (bwdpi_conntrack[i][4] == 500 || bwdpi_conntrack[i][4] == 4500)																		//wifi caling
					bwdpi_conntrack[i][5] =	'<div  class="t_item">' +
							'<span class="t_label catrow cat' + c_voip + '"' + size + '>Wi-Fi Calling</span>' +				
							'<span class="t_mark  catrow cat' + c_voip + '"' + size + '>MARK:' + mark + '</span>' +
							'<div>';	

				if (bwdpi_conntrack[i][2] >= 16384 && bwdpi_conntrack[i][2] <= 16415)																	//facetime
					bwdpi_conntrack[i][5] =	'<div  class="t_item">' +
							'<span class="t_label catrow cat' + c_voip + '"' + size + '>Facetime</span>' +				
							'<span class="t_mark  catrow cat' + c_voip + '"' + size + '>MARK:' + mark + '</span>' +
							'<div>';	

				if (bwdpi_conntrack[i][7] == 8 && (bwdpi_conntrack[i][4] == 80 || bwdpi_conntrack[i][4] == 443) && bwdpi_conntrack[i][0] == "tcp" )	{	//game downloads
					label = "Game Transfering: " + label;
					if (label.length > 27)	size='style="font-size: 75%;"';
					bwdpi_conntrack[i][5] =	'<div  class="t_item">' +
							'<span class="t_label catrow cat' + c_default + '"' + size + '>' + label + '</span>' +				
							'<span class="t_mark  catrow cat' + c_default + '"' + size + '>MARK:' + mark + '</span>' +
							'<div>';	
				}
				if (eval_rule(gamerule, bwdpi_conntrack[i][0], bwdpi_conntrack[i][2], bwdpi_conntrack[i][4], bwdpi_conntrack[i][1], bwdpi_conntrack[i][3], bwdpi_conntrack[i][7], bwdpi_conntrack[i][6]))
					bwdpi_conntrack[i][5] =	'<div  class="t_item">' +
							'<span class="t_label catrow cat' + gamerule[18] + '"' + size + '>Game Rule: Untracked</span>' +				
							'<span class="t_mark  catrow cat' + gamerule[18] + '"' + size + '>MARK:' + mark + '</span>' +
							'<div>';				
				
				if (eval_rule(rule1, bwdpi_conntrack[i][0], bwdpi_conntrack[i][2], bwdpi_conntrack[i][4], bwdpi_conntrack[i][1], bwdpi_conntrack[i][3], bwdpi_conntrack[i][7], bwdpi_conntrack[i][6]))
					bwdpi_conntrack[i][5] =	'<div  class="t_item">' +
							'<span class="t_label catrow cat' + rule1[18] + '"' + size + '>Rule1</span>' +				
							'<span class="t_mark  catrow cat' + rule1[18] + '"' + size + '>MARK:' + mark + '</span>' +
							'<div>';	
				if (eval_rule(rule2, bwdpi_conntrack[i][0], bwdpi_conntrack[i][2], bwdpi_conntrack[i][4], bwdpi_conntrack[i][1], bwdpi_conntrack[i][3], bwdpi_conntrack[i][7], bwdpi_conntrack[i][6]))
					bwdpi_conntrack[i][5] =	'<div  class="t_item">' +
							'<span class="t_label catrow cat' + rule2[18] + '"' + size + '>Rule2</span>' +				
							'<span class="t_mark  catrow cat' + rule2[18] + '"' + size + '>MARK:' + mark + '</span>' +
							'<div>';
				if (eval_rule(rule3, bwdpi_conntrack[i][0], bwdpi_conntrack[i][2], bwdpi_conntrack[i][4], bwdpi_conntrack[i][1], bwdpi_conntrack[i][3], bwdpi_conntrack[i][7], bwdpi_conntrack[i][6]))
					bwdpi_conntrack[i][5] =	'<div  class="t_item">' +
							'<span class="t_label catrow cat' + rule3[18] + '"' + size + '>Rule3</span>' +				
							'<span class="t_mark  catrow cat' + rule3[18] + '"' + size + '>MARK:' + mark + '</span>' +
							'<div>';
				if (eval_rule(rule4, bwdpi_conntrack[i][0], bwdpi_conntrack[i][2], bwdpi_conntrack[i][4], bwdpi_conntrack[i][1], bwdpi_conntrack[i][3], bwdpi_conntrack[i][7], bwdpi_conntrack[i][6]))
					bwdpi_conntrack[i][5] =	'<div  class="t_item">' +
							'<span class="t_label catrow cat' + rule4[18] + '"' + size + '>Rule4</span>' +				
							'<span class="t_mark  catrow cat' + rule4[18] + '"' + size + '>MARK:' + mark + '</span>' +
							'<div>';
							
				//PRETTY PRINT LOCAL DEVICE NAME NEXT TO IPv4 address
				//(has to be placed after evaluation of custom rules due to injecting HTML into LocalIP field)
				if (typeof device[bwdpi_conntrack[i][1]] != "undefined")
				{
					bwdpi_conntrack[i][1] =   
					  '<div  title="' + bwdpi_conntrack[i][1].split('.')[3].padStart(3, '#') + '" class="localdeviceip">' + bwdpi_conntrack[i][1] + '</div>' + 
					  '<span class="devicename">'  + device[bwdpi_conntrack[i][1]].name + '</span>'
				}
					
			}

			tabledata[j] = bwdpi_conntrack[i];
			j++;
		}
    }
	j <= 30 ? tabledata.length = 30 : tabledata.length = j ;		//table will always contain at least 30 blank entries to maintain some scroll distance	
	//draw table
	updateTable()	
}

function updateTable()
{
	//table header
	var header = new Array(6);
		header[0]='<th width="5%"  style="cursor: pointer;" onclick="sortmode=1; updateTable()" >Proto</th>';
		header[1]='<th width="28%" style="cursor: pointer;" onclick="sortmode=2; updateTable()" >Local IP</th>';
		header[2]='<th width="6%"  style="cursor: pointer;" onclick="sortmode=3; updateTable()" >LPort</th>';
		header[3]='<th width="28%" style="cursor: pointer;" onclick="sortmode=4; updateTable()" >Remote IP</th>';
		header[4]='<th width="6%"  style="cursor: pointer;" onclick="sortmode=5; updateTable()" >RPort</th>';
		header[5]='<th width="27%" style="cursor: pointer;" onclick="sortmode=6; updateTable()" >Application</th>';


	//sort table data
	switch(sortmode) {
	  case 1:
		// sort by protocol
		header[0]='<th width="5%"  style="cursor: pointer; box-shadow: rgb(255, 204, 0) 0px -1px 0px 0px inset;" onclick="sortmode=7; updateTable()" >Proto</th>';
		tabledata.sort(function(a,b) {return a[5].localeCompare(b[5])} );
		tabledata.sort(function(a,b) {return a[0].localeCompare(b[0])} );
		break;
	  case 2:
		// sort by local IP
		header[1]='<th width="210px" style="cursor: pointer; box-shadow: rgb(255, 204, 0) 0px -1px 0px 0px inset;" onclick="sortmode=8; updateTable()" >Local IP</th>';
		tabledata.sort(function(a,b) {return a[5].localeCompare(b[5])} );
		tabledata.sort(function(a,b) {return a[1].localeCompare(b[1])} );
		break;
	  case 3:
		// sort by local port
		header[2]='<th width="6%"  style="cursor: pointer; box-shadow: rgb(255, 204, 0) 0px -1px 0px 0px inset;" onclick="sortmode=9; updateTable()" >Port</th>';
		tabledata.sort(function(a,b) {return a[5].localeCompare(b[5])} );
		tabledata.sort(function(a,b) {return a[2]-b[2]} );
		break;
	  case 4:
		// sort by remote IP
		header[3]='<th width="28%" style="cursor: pointer; box-shadow: rgb(255, 204, 0) 0px -1px 0px 0px inset;" onclick="sortmode=10; updateTable()" >Remote IP</th>';
		tabledata.sort(function(a,b) {return a[5].localeCompare(b[5])} );
		tabledata.sort(function(a,b) {return full_IPv6(a[3]).localeCompare(full_IPv6(b[3]))} );
		break;
	  case 5:
		// sort by remote port
		header[4]='<th width="6%"  style="cursor: pointer; box-shadow: rgb(255, 204, 0) 0px -1px 0px 0px inset;" onclick="sortmode=11; updateTable()" >Port</th>';
		tabledata.sort(function(a,b) {return a[5].localeCompare(b[5])} );
		tabledata.sort(function(a,b) {return a[4]-b[4]} );
		break;
	  case 6:
		// sort by label
		header[5]='<th width="27%" style="cursor: pointer; box-shadow: rgb(255, 204, 0) 0px -1px 0px 0px inset;" onclick="sortmode=12; updateTable()" >Application</th>';
		tabledata.sort(function(a,b) {return a[1].localeCompare(b[1])} );
		tabledata.sort(function(a,b) {return a[5].localeCompare(b[5])} );
		break;
	  case 7:
		// sort by protocol
		header[0]='<th width="5%"  style="cursor: pointer; box-shadow: rgb(255, 204, 0) 0px 1px 0px 0px inset;" onclick="sortmode=1; updateTable()" >Proto</th>';
		tabledata.sort(function(a,b) {return a[5].localeCompare(b[5])} );
		tabledata.sort(function(a,b) {return b[0].localeCompare(a[0])} );
		break;
	  case 8:
		// sort by local IP
		header[1]='<th width="28%" style="cursor: pointer; box-shadow: rgb(255, 204, 0) 0px 1px 0px 0px inset;" onclick="sortmode=2; updateTable()" >Local IP</th>';
		tabledata.sort(function(a,b) {return a[5].localeCompare(b[5])} );
		tabledata.sort(function(a,b) {return b[1].localeCompare(a[1])} );
		break;
	  case 9:
		// sort by local port
		header[2]='<th width="6%"  style="cursor: pointer; box-shadow: rgb(255, 204, 0) 0px 1px 0px 0px inset;" onclick="sortmode=3; updateTable()" >Port</th>';
		tabledata.sort(function(a,b) {return a[5].localeCompare(b[5])} );
		tabledata.sort(function(a,b) {return b[2]-a[2]} );
		break;
	  case 10:
		// sort by remote IP
		header[3]='<th width="28%" style="cursor: pointer; box-shadow: rgb(255, 204, 0) 0px 1px 0px 0px inset;" onclick="sortmode=4; updateTable()" >Remote IP</th>';
		tabledata.sort(function(a,b) {return a[5].localeCompare(b[5])} );
		tabledata.sort(function(a,b) {return full_IPv6(b[3]).localeCompare(full_IPv6(a[3]))} );
		break;
	  case 11:
		// sort by remote port
		header[4]='<th width="6%"  style="cursor: pointer; box-shadow: rgb(255, 204, 0) 0px 1px 0px 0px inset;" onclick="sortmode=5; updateTable()" >Port</th>';
		tabledata.sort(function(a,b) {return a[5].localeCompare(b[5])} );
		tabledata.sort(function(a,b) {return b[4]-a[4]} );
		break;
	  case 12:
		// sort by label
		header[5]='<th width="27%" style="cursor: pointer; box-shadow: rgb(255, 204, 0) 0px 1px 0px 0px inset;" onclick="sortmode=6; updateTable()" >Application</th>';
		tabledata.sort(function(a,b) {return a[1].localeCompare(b[1])} );
		tabledata.sort(function(a,b) { return b[5].localeCompare(a[5])} );
		break;
	}
	
	//generate table
	var tbl  = document.getElementById('tableContainer');
	var code = '<tr class="row_title">'+header[0]+header[1]+header[2]+header[3]+header[4]+header[5]+'</tr>';
	
    for(var i = 0; i < tabledata.length; i++){
		if(tabledata[i])
		{
			code += '<tr class="row_tr data_tr" row_tr_idx="' + i +' ">';
				code += '<td>' + tabledata[i][0] +'</td>';
				code += '<td>' + tabledata[i][1] +'</td>';
				code += '<td>' + tabledata[i][2] +'</td>';
				code += '<td>' + tabledata[i][3] +'</td>';
				code += '<td>' + tabledata[i][4] +'</td>';
				code += '<td>' + tabledata[i][5] +'</td></tr>';
		}else
		{
			code += '<tr class="row_tr data_tr" row_tr_idx="' + i +' "></tr>';
		}
    }
	if (tabledata[tablesize - 1] )
	{	
		code += '<tr class="row_tr data_tr" row_tr_idx="' + tablesize +' "><td style="text-align:center; font-weight:bold;" colspan="7">Reached table limit.  Please use device filter.</td>'
	}
	tbl.innerHTML = code;
}


function comma(n) {
    n = '' + n;
    var p = n;
    while ((n = n.replace(/(\d+)(\d{3})/g, '$1,$2')) != p) p = n;
    return n;
}

function get_devicenames()
{				
	// populate device["IP"].mac from nvram variable "dhcp_staticlist"
	decodeURIComponent('<% nvram_char_to_ascii("", "dhcp_staticlist"); %>').split("<").forEach( element => {
		if ( element.split(">")[1] ){
			device[element.split(">")[1]] = { mac:element.split(">")[0].toUpperCase() , name:"DEBUG: NVRAM" };
		}
	});

	// populate device["IP"].mac from arp table
	[<% get_arp_table(); %>].forEach( element => {
		if ( element[3] ){
			device[element[0]] = { mac:element[3].toUpperCase() , name:"DEBUG: ARP" };
		}
	 });


	//populate device["IP"].mac from the dhcp table
	// disabled due to <get_leases_array()> taking 1 second to load.  This code is ran elsewhere asynchronously
	// populate device["IP"].mac from dhcp table
	// <'%' get_leases_array(); '%'>			//returns variable named leasearray[] 
	// leasearray.forEach( element => {
		// if ( element[1] ){
			// device[element[2]] = { mac:element[1].toUpperCase() , name:"DEBUG: DHCP" };
		// }
	// });
		
		
	//instead temporarily populate device["IP"].name from dhcp table		
	// used as stopgap as source of partial information on page load until complete information is later available from asynchronous code
	// is NOT ideal since the names using this method do not reflect nicknames and sometimes return "*" instead of a device name
	dhcpnamelist = <% IP_dhcpLeaseInfo(); %>
	dhcpnamelist.forEach( element => {
		if ( element[0] ){
			if( device[element[0]] )
				device[element[0]].name = element[1]+'~';
			else
				device[element[0]] = { mac:undefined , name:element[1]+'-' };
		}
	});
		
	// populate device["IP"].name from device["IP"].mac saved in /jffs/nmp_cl_json.js
	// clientlist = is data set from /jffs/nmp_cl_json.js
	for (var i in device) {
		if (typeof clientlist[device[i].mac] != "undefined")
		{
			if(clientlist[device[i].mac].nickName != "")
			{
				device[i].name = clientlist[device[i].mac].nickName;
			}
			else if(clientlist[device[i].mac].name != "")
			{
				device[i].name = clientlist[device[i].mac].name;
			}
		}
	}	
}

function update_devicenames(leasearray)
{
	// this code was not ran on page load since the data source needed to be ran asynchronously
	leasearray.forEach( element => {
		if ( element[1] ){
			
			mac = element[1].toUpperCase();
			ip = element[2];
			
			//update device["IP"].mac from DHCP table
			device[ip] = { mac:mac , name:"DEBUG: DHCP" };
			
			//update device{"IP"].name from /jffs/nmp_cl_json.js
			if (typeof clientlist[mac] != "undefined")
			{
				if(clientlist[mac].nickName != "")
				{
					device[ip].name = clientlist[mac].nickName;
				}
				else if(clientlist[mac].name != "")
				{
					device[ip].name = clientlist[mac].name;
				}
			}
			
			//update device filter drop down formated values
			document.getElementById(ip).innerHTML = ip.padEnd(18,' ') + device[ip].name;
		}
	});
}

function populate_devicefilter(){
	var code = '<option value="*" > </option>';
	//Presort clients before adding clients into devicefilter to make it easier to read
	keysSorted = Object.keys(device).sort(function(a,b){ return ip2dec(a)-ip2dec(b) })									// sort by IP
	//keysSorted = Object.keys(device).sort(function(a,b){ return device[a].name.localeCompare(device[b].name) })		// sort by device name
	for (i = 0; i < keysSorted.length; i++) {
	  key = keysSorted[i];
	  code += '<option id="' + key + '" value="' + key + '">' + key.padEnd(18,' ') + device[key].name + "</option>\n";
	}
	document.getElementById('devicefilter').innerHTML=code;
}


function initial() {
	set_FreshJR_mod_vars();
	get_devicenames();						//used for printing name next to IP
	populate_devicefilter();				//used to populate drop down filter
    show_menu();
    refreshRate = document.getElementById('refreshrate').value;
	deviceFilter = document.getElementById('devicefilter').value;
    get_data();
    //draw_conntrack_table();  get_data() already draws table	
	if (qos_mode == 0){		//if QoS is invalid
		document.getElementById('filter_device').style.display = "none";
		document.getElementById('tracked_connections').style.display = "none";
		document.getElementById('refresh_data').style.display = "none";
	}
     $.ajax({
        url: "Main_DHCPStatus_Content.asp", 
        success:   function(result){ 
			result = result.match(/leasearray=([\s\S]*?);/);
			if (result[1]){
				update_devicenames(eval(result[1])); //regex data string into actual array
			}
        }
      });
}


function get_qos_class(category, appid) {
    var i, j, catlist, rules;
    if ((category == 0 && appid == 0) || (qos_mode != 2))
        return 7;
    for (i = 0; i < bwdpi_app_rulelist_row.length - 2; i++) {
        rules = bwdpi_app_rulelist_row[i];
        if (i == 0)
            rules += ",18,19";
        else if (i == 4)
            rules += ",28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43";
        else if (i == 5)
            rules += ",12";
        catlist = rules.split(",");
        for (j = 0; j < catlist.length; j++) {
            if (catlist[j] == category) {
                return i;
            }
        }
    }
    return 7;
}

function compIPV6(input) {
    input = input.replace(/\b(?:0+:){2,}/, ':');
    return input.replace(/(^|:)0{1,4}/g, ':');
}

function create_rule(Proto, Lport, Rport, Lip, Rip, Mark, Dst){
	var rule =[];		//user rule in specific format later used for quick evaluation
	//rule[0]=enabled filters flag (8bit)
	//rule[1]=protocol
	//rule[2]=Local port inverse match (!) bool
	//rule[3]=Local port start
	//rule[4]=Local port end
	//rule[5]=Local port multimatch array
	//rule[6]=Remote port inverse match (!) bool
	//rule[7]=Remote port start
	//rule[8]=Remote port end
	//rule[9]=Remote port multimatch array
	//rule[10]=Local IP inverse match (!) bool
	//rule[11]=Local IP start
	//rule[12]=Local IP end
	//rule[13]=Remote IP inverse match (!) bool
	//rule[14]=Remote IP start
	//rule[15]=Remote IP end
	//rule[16]=Mark (General Category Match)
	//rule[17]=Mark (Specific Traffic Match)
    //rule[18]=QoS Destination
  
  rule[0]=0;
  if (Dst)	rule[18]=bwdpi_app_rulelist_row.indexOf(cat_id_array[Dst].toString());
  Proto = Proto.toLowerCase();
	if ( Proto )
	{
		rule[1]=Proto;
		if( Lport ) 
		{
			if(Lport.startsWith("!")) {
				rule[2]=1;
				Lport=Lport.replace("!", "");
			}
			if(Lport.includes(",")) {
				rule[0]+=4;
				rule[5]=Lport.split(",").map(Number);;
			}
			else if (Lport.includes(":")) {
				rule[0]+=1;
				rule[3]=parseInt(Lport.split(':')[0]);
				rule[4]=parseInt(Lport.split(':')[1]);
			}
			else{
				rule[0]+=1;
				rule[3]=parseInt(Lport);
				rule[4]=rule[3];
			}
		}

		if( Rport ) 
		{
			if(Rport.startsWith("!")) {
				rule[6]=1;
				Rport=Rport.replace("!", "");
			}
			if(Rport.includes(",")) {
				rule[0]+=8;
				rule[9]=Rport.split(",").map(Number);;
			}
			else if (Rport.includes(":")) {
				rule[0]+=2;
				rule[7]=parseInt(Rport.split(':')[0]);
				rule[8]=parseInt(Rport.split(':')[1]);
			}
			else{
				rule[0]+=2;
				rule[7]=parseInt(Rport);
				rule[8]=rule[7];
			}
		}
	}
	
	if ( Lip )
	{
		rule[0]+=16;
		if(Lip.startsWith("!")) {
			rule[10]=1;
			Lip=Lip.replace("!", "");
		}
		
		if(Lip.includes("/")) {
			rule[11]=cidr_start(Lip);
			rule[12]=cidr_end(Lip);
		}
		else{
			rule[11]=ip2dec(Lip);
			rule[12]=rule[11];
		}
	}
	
	if ( Rip )
	{
		rule[0]+=32;
		if(Rip.startsWith("!")) {
			rule[13]=1;
			Rip=Rip.replace("!", "");
		}
		
		if(Rip.includes("/")) {
			rule[14]=cidr_start(Rip);
			rule[15]=cidr_end(Rip);
		}
		else{
			rule[14]=ip2dec(Rip);
			rule[15]=rule[14];
		}
	}
	
	if ( Mark.length == 6 )
	{
		rule[0]+=64;
		rule[16]=parseInt(Mark.substr(0,2),16);
		
		if (Mark.substr(-4) != "****")
		{
			rule[0]+=128;
			rule[17]=parseInt(Mark.substr(-4),16);
		}
		
	}

	// console.log(rule);
	return rule;
};

function eval_rule(rule, CProto, CLport, CRport, CLip, CRip, CCat, CId){

	//eval false if rule has no filters or destination specified
	if (!rule[0] || (rule[18]==undefined) ) 	
	{
		// console.log("rule is not configured");
		return 0;
	}
	
	//if rule has local/remote ports specified
	if (rule[0] & 15)
	{
		if ( rule[1] != "both" && CProto != rule[1])
		{
			// console.log("protocol mismatch");
			return 0;
		}
		
		if ((rule[0] & 15) <= 3 )							//if port rule is NOT a multiport match
		{
			if ( (rule[0] & 1) && !((CLport >= rule[3] && CLport <= rule[4])^(rule[2])) )
			{    	
				// console.log("local port mismatch");
				return 0;
			}
			if ( (rule[0] & 2) && !((CRport >= rule[7] && CRport <= rule[8])^(rule[6])) )
			{
				// console.log("remote port mismatch");
				return 0;
			}
			
		}
		else if (( rule[0] & 15) == 4 )						//if port rule is ONLY a local multiport match
		{
			var match=false;
			for (var i = 0; i < rule[5].length; i++) {
				if(rule[5][i] == CLport) 	match=true;
			}
			if (rule[2]) 					match=!(match);
			if (match == false)
			{
			  // console.log("local multiport mismatch");
			  return 0;
			}

		}
		else if (( rule[0] & 15) == 8 )						//if port rule is ONLY a remote multiport match
		{
		    var match=false;
		    for (var i = 0; i < rule[9].length; i++) {
		  	  if(rule[9][i] == CRport) 	match=true;
		    }
		    if (rule[6]) 				match=!(match);
		    if (match == false)
		    {
			  // console.log("remote multiport mismatch");
			  return 0;
		    }

		}
		else
		{
			//console.log("improper configuration of port rule");
			return 0;									//eval false since multiport match cannot be simultanously used with other port match
		}
	}
	

	// if rule has local IP specified
	if ((rule[0] & 16) )
	{
	  CLip=ip2dec(CLip);
	  if ( !((CLip >= rule[11] && CLip <= rule[12])^(rule[10])) )
	    {
	      // console.log("local ip mismatch");
		  return 0;
		}
	  }

	  // if rule has remote IP specified
	if (rule[0] & 32)
	{
	  CRip=ip2dec(CRip);
	  if ( !((CRip >= rule[14] && CRip <= rule[15])^(rule[13])) )
	  {
	    //console.log("remote ip mismatch");
		return 0;
	  }
	}

	// if rule has mark cat specified
	if ( (rule[0] & 64) && (rule[16] != CCat) )
	{
	  // console.log("category mismatch");
	  return 0;
    }
		
	// if rule has mark id specified
	if ( (rule[0] & 128) && (rule[17] != CId) )
	{
	  // console.log("traffic ID mismatch");
	  return 0;
	}
	  
	// console.log("rule matches current connection");
	return 1;

}

function redraw() {
    var code;
    switch (qos_mode) {
        case 0: // Disabled
            document.getElementById('dl_tr').style.display = "none";
            document.getElementById('ul_tr').style.display = "none";
            document.getElementById('no_qos_notice').style.display = "";
            return;
        case 3: // Bandwith Limiter
            document.getElementById('dl_tr').style.display = "none";
            document.getElementById('ul_tr').style.display = "none";
            document.getElementById('limiter_notice').style.display = "";
            return;
        case 1: // Traditional
            document.getElementById('dl_tr').style.display = "none";
            document.getElementById('tqos_notice').style.display = "";
            break;
        case 2: // Adaptive
            if (pie_obj_dl != undefined) pie_obj_dl.destroy();
            var ctx_dl = document.getElementById("pie_chart_dl").getContext("2d");
            tcdata_lan_array.sort(function(a, b) {
                return a[0] - b[0]
            });
            code = draw_chart(tcdata_lan_array, ctx_dl, "dl");
            document.getElementById('legend_dl').innerHTML = code;
            break;
    }
    if (pie_obj_ul != undefined) pie_obj_ul.destroy();
    var ctx_ul = document.getElementById("pie_chart_ul").getContext("2d");
    tcdata_wan_array.sort(function(a, b) {
        return a[0] - b[0]
    });
    code = draw_chart(tcdata_wan_array, ctx_ul, "ul");
    document.getElementById('legend_ul').innerHTML = code;
    pieOptions.animation = false; // Only animate first time
}

function get_data() {
    if (timedEvent) {
        clearTimeout(timedEvent);
        timedEvent = 0;
    }
    $.ajax({
        url: '/ajax_gettcdata.asp',
        dataType: 'script',
        error: function(xhr) {
            get_data();
        },
        success: function(response) {
            redraw();
            draw_conntrack_table();
            if (refreshRate > 0)
                timedEvent = setTimeout("get_data();", refreshRate * 1000);
        }
    });
}

function draw_chart(data_array, ctx, pie) {
    var code = '<table><thead style="text-align:left;"><tr><th style="padding-left:5px;">Class</th><th style="padding-left:5px;">Total</th><th style="padding-left:20px;">Rate</th><th style="padding-left:20px;">Packet rate</th></tr></thead>';
    var code_delay_append = '';
	var values_array = [];
    var labels_array = [];
    for (i = 0; i < data_array.length - 1; i++) {
        var value = parseInt(data_array[i][1]);
        var tcclass = parseInt(data_array[i][0]);
        var rate;
        if (qos_mode == 2) {
            var index = 0;
            for (j = 1; j < cat_id_array.length; j++) {
                if (cat_id_array[j] == bwdpi_app_rulelist_row[i]) {
                    index = j;
                    break;
                }
            }
            var label = category_title[index];
        } else {
            tcclass = tcclass / 10;
            var label = category_title[tcclass];
            if (label == undefined) {
                label = "Class " + tcclass;
            }
        }
        labels_array.push(label);
        values_array.push(value);
        var unit = " Bytes";
        if (value > 1024) {
            value = value / 1024;
            unit = " KB";
        }
        if (value > 1024) {
            value = value / 1024;
            unit = " MB";
        }
        if (value > 1024) {
            value = value / 1024;
            unit = " GB";
        }
		if (qos_mode == 2 && i == 6) {
			code_delay_append += '<tr><td style="word-wrap:break-word;padding-left:5px;padding-right:5px;border:1px #2f3a3e solid; border-radius:5px;background-color:' + color[i] + ';margin-right:10px;line-height:20px;">' + label + '</td>';
			code_delay_append += '<td style="padding-left:5px;">' + value.toFixed(2) + unit + '</td>';
			rate = comma(data_array[i][2]);
			code_delay_append += '<td style="padding-left:20px;">' + rate.replace(/([0-9,])([a-zA-Z])/g, '$1 $2') + '</td>';
			rate = comma(data_array[i][3]);
			code_delay_append += '<td style="padding-left:20px;">' + rate.replace(/([0-9,])([a-zA-Z])/g, '$1 $2') + '</td></tr>';
		}
		else
		{
			code += '<tr><td style="word-wrap:break-word;padding-left:5px;padding-right:5px;border:1px #2f3a3e solid; border-radius:5px;background-color:' + color[i] + ';margin-right:10px;line-height:20px;">' + label + '</td>';
			code += '<td style="padding-left:5px;">' + value.toFixed(2) + unit + '</td>';
			rate = comma(data_array[i][2]);
			code += '<td style="padding-left:20px;">' + rate.replace(/([0-9,])([a-zA-Z])/g, '$1 $2') + '</td>';
			rate = comma(data_array[i][3]);
			code += '<td style="padding-left:20px;">' + rate.replace(/([0-9,])([a-zA-Z])/g, '$1 $2') + '</td></tr>';
		}
    }
	code += code_delay_append;
    code += '</table>';
    var pieData = {
        labels: labels_array,
        datasets: [{
            data: values_array,
            backgroundColor: color,
            hoverBackgroundColor: color,
            borderColor: "#444",
            borderWidth: "1"
        }]
    };
    var pie_obj = new Chart(ctx, {
        type: 'pie',
        data: pieData,
        options: pieOptions
    });
    if (pie == "ul")
        pie_obj_ul = pie_obj;
    else
        pie_obj_dl = pie_obj;
    return code;
}

function FreshJR_mod_toggle()
{
	var FreshJR_div = document.getElementById('FreshJR_mod');
	var FreshJR_toggle = document.getElementById('FreshJR_mod_toggle');
	if (FreshJR_div.style.display == "none")
	{
		FreshJR_div.style.display = "block";
		FreshJR_toggle.innerHTML = "FreshJR Mod <small>(Hide Modification)</small>";
	}
	else
	{
		FreshJR_div.style.display = "none";
		FreshJR_toggle.innerHTML = "FreshJR Mod <small>(Customize)</small>";
	}
}

function set_FreshJR_mod_vars()
{
	if (qos_mode != 2) {
		var element = document.getElementById('FreshJR_mod_toggle')
		element.innerHTML="FreshJR Mod <small>(Adaptive QoS is Disabled)</small>";
		element.removeAttribute("onclick");
		element.style.cursor = "";
	}
	else
	{
		var FreshJR_nvram1 = decodeURIComponent('<% nvram_char_to_ascii("",fb_comment); %>').replace(/>/g,";").split(";");			// nvram variables from feedbackpage repurposed for use with FreshJR_QOS
		var FreshJR_nvram2 = decodeURIComponent('<% nvram_char_to_ascii("",fb_email_dbg); %>').replace(/>/g,";").split(";");		// nvram variables from feedbackpage repurposed for use with FreshJR_QOS 
		if (FreshJR_nvram1.length == 21)
		{
			e1=FreshJR_nvram1[0];				document.getElementById('e1').value=e1;
			e2=FreshJR_nvram1[1];				document.getElementById('e2').value=e2;
			e3=FreshJR_nvram1[2].toLowerCase();	document.getElementById('e3').value=e3;
			e4=FreshJR_nvram1[3];				document.getElementById('e4').value=e4;
			e5=FreshJR_nvram1[4];				document.getElementById('e5').value=e5;
			e6=FreshJR_nvram1[5];				document.getElementById('e6').value=e6;
			e7=FreshJR_nvram1[6];				document.getElementById('e7').value=e7;
			rule1=create_rule(e3, e4, e5, e1, e2, e6, e7);
			
			f1=FreshJR_nvram1[7];				document.getElementById('f1').value=f1;
			f2=FreshJR_nvram1[8];				document.getElementById('f2').value=f2;
			f3=FreshJR_nvram1[9].toLowerCase();	document.getElementById('f3').value=f3;
			f4=FreshJR_nvram1[10];				document.getElementById('f4').value=f4;
			f5=FreshJR_nvram1[11];				document.getElementById('f5').value=f5;
			f6=FreshJR_nvram1[12];				document.getElementById('f6').value=f6;
			f7=FreshJR_nvram1[13];				document.getElementById('f7').value=f7;
			rule2=create_rule(f3, f4, f5, f1, f2, f6, f7);
			
			g1=FreshJR_nvram1[14];				document.getElementById('g1').value=g1;
			g2=FreshJR_nvram1[15];				document.getElementById('g2').value=g2;
			g3=FreshJR_nvram1[16].toLowerCase();document.getElementById('g3').value=g3;
			g4=FreshJR_nvram1[17];				document.getElementById('g4').value=g4;
			g5=FreshJR_nvram1[18];				document.getElementById('g5').value=g5;
			g6=FreshJR_nvram1[19];				document.getElementById('g6').value=g6;
			g7=FreshJR_nvram1[20];				document.getElementById('g7').value=g7;
			rule3=create_rule(g3, g4, g5, g1, g2, g6, g7);
		}	
		if (FreshJR_nvram2.length == 49)
		{
			h1=FreshJR_nvram2[0];				document.getElementById('h1').value=h1;
			h2=FreshJR_nvram2[1].toLowerCase(); document.getElementById('h2').value=h2;
			h3=FreshJR_nvram2[2];				document.getElementById('h3').value=h3;
			h4=FreshJR_nvram2[3];				document.getElementById('h4').value=h4;	
			h5=FreshJR_nvram2[4];				document.getElementById('h5').value=h5;
			h6=FreshJR_nvram2[5];				document.getElementById('h6').value=h6;
			h7=FreshJR_nvram2[6];				document.getElementById('h7').value=h7;
			rule4=create_rule(h3, h4, h5, h1, h2, h6, h7);
			
			r1=FreshJR_nvram2[7];				document.getElementById('r1').value=r1;
			d1=FreshJR_nvram2[8];				document.getElementById('d1').value=d1;
			appdb1=create_rule("", "", "", "", "", r1, d1);
			
			r2=FreshJR_nvram2[9]; 				document.getElementById('r2').value=r2;
			d2=FreshJR_nvram2[10];				document.getElementById('d2').value=d2;
			appdb2=create_rule("", "", "", "", "", r2, d2);
			
			r3=FreshJR_nvram2[11];				document.getElementById('r3').value=r3;
			d3=FreshJR_nvram2[12];				document.getElementById('d3').value=d3;
			appdb3=create_rule("", "", "", "", "", r3, d3);
			
			r4=FreshJR_nvram2[13];				document.getElementById('r4').value=r4;
			d4=FreshJR_nvram2[14];				document.getElementById('d4').value=d4;
			appdb4=create_rule("", "", "", "", "", r4, d4);
			

			gameCIDR=FreshJR_nvram2[15];		document.getElementById('gameCIDR').value=gameCIDR;		
			if (gameCIDR) 
				gamerule=create_rule("both", "", "!80,443", gameCIDR, "", "000000", "1");
			else
				gamerule=create_rule("", "", "", "", "", "", "");
			ruleFLAG=FreshJR_nvram2[16];
			
			
			drp0=parseInt(FreshJR_nvram2[17]);		if (drp0 >= 5 && drp0 < 100) document.getElementById('drp0').value=drp0;
			drp1=parseInt(FreshJR_nvram2[18]);		if (drp1 >= 5 && drp1 < 100) document.getElementById('drp1').value=drp1;
			drp2=parseInt(FreshJR_nvram2[19]);		if (drp2 >= 5 && drp2 < 100) document.getElementById('drp2').value=drp2;
			drp3=parseInt(FreshJR_nvram2[20]);		if (drp3 >= 5 && drp3 < 100) document.getElementById('drp3').value=drp3;
			drp4=parseInt(FreshJR_nvram2[21]);		if (drp4 >= 5 && drp4 < 100) document.getElementById('drp4').value=drp4;
			drp5=parseInt(FreshJR_nvram2[22]);		if (drp5 >= 5 && drp5 < 100) document.getElementById('drp5').value=drp5;
			drp6=parseInt(FreshJR_nvram2[23]);		if (drp6 >= 5 && drp6 < 100) document.getElementById('drp6').value=drp6;
			drp7=parseInt(FreshJR_nvram2[24]);		if (drp7 >= 5 && drp7 < 100) document.getElementById('drp7').value=drp7;
			
			dcp0=parseInt(FreshJR_nvram2[25]);		if (dcp0 >= 5 && dcp0 <= 100) document.getElementById('dcp0').value=dcp0;
			dcp1=parseInt(FreshJR_nvram2[26]);		if (dcp0 >= 5 && dcp0 <= 100) document.getElementById('dcp1').value=dcp1;
			dcp2=parseInt(FreshJR_nvram2[27]);		if (dcp0 >= 5 && dcp0 <= 100) document.getElementById('dcp2').value=dcp2;
			dcp3=parseInt(FreshJR_nvram2[28]);		if (dcp0 >= 5 && dcp0 <= 100) document.getElementById('dcp3').value=dcp3;
			dcp4=parseInt(FreshJR_nvram2[29]);		if (dcp0 >= 5 && dcp0 <= 100) document.getElementById('dcp4').value=dcp4;
			dcp5=parseInt(FreshJR_nvram2[30]);		if (dcp0 >= 5 && dcp0 <= 100) document.getElementById('dcp5').value=dcp5;
			dcp6=parseInt(FreshJR_nvram2[31]);		if (dcp0 >= 5 && dcp0 <= 100) document.getElementById('dcp6').value=dcp6;
			dcp7=parseInt(FreshJR_nvram2[32]);		if (dcp0 >= 5 && dcp0 <= 100) document.getElementById('dcp7').value=dcp7;
			
			urp0=parseInt(FreshJR_nvram2[33]);		if (urp0 >= 5 && urp0 < 100) document.getElementById('urp0').value=urp0;
			urp1=parseInt(FreshJR_nvram2[34]);		if (urp1 >= 5 && urp1 < 100) document.getElementById('urp1').value=urp1;
			urp2=parseInt(FreshJR_nvram2[35]);		if (urp2 >= 5 && urp2 < 100) document.getElementById('urp2').value=urp2;
			urp3=parseInt(FreshJR_nvram2[36]);		if (urp3 >= 5 && urp3 < 100) document.getElementById('urp3').value=urp3;
			urp4=parseInt(FreshJR_nvram2[37]);		if (urp4 >= 5 && urp4 < 100) document.getElementById('urp4').value=urp4;
			urp5=parseInt(FreshJR_nvram2[38]);		if (urp5 >= 5 && urp5 < 100) document.getElementById('urp5').value=urp5;
			urp6=parseInt(FreshJR_nvram2[39]);		if (urp6 >= 5 && urp6 < 100) document.getElementById('urp6').value=urp6;
			urp7=parseInt(FreshJR_nvram2[40]);		if (urp7 >= 5 && urp7 < 100) document.getElementById('urp7').value=urp6;
			
			ucp0=parseInt(FreshJR_nvram2[41]);		if (ucp0 >= 5 && ucp0 <= 100) document.getElementById('ucp0').value=ucp0;
			ucp1=parseInt(FreshJR_nvram2[42]);		if (ucp1 >= 5 && ucp1 <= 100) document.getElementById('ucp1').value=ucp1;
			ucp2=parseInt(FreshJR_nvram2[43]);		if (ucp2 >= 5 && ucp2 <= 100) document.getElementById('ucp2').value=ucp2;
			ucp3=parseInt(FreshJR_nvram2[44]);		if (ucp3 >= 5 && ucp3 <= 100) document.getElementById('ucp3').value=ucp3;
			ucp4=parseInt(FreshJR_nvram2[45]);		if (ucp4 >= 5 && ucp4 <= 100) document.getElementById('ucp4').value=ucp4;
			ucp5=parseInt(FreshJR_nvram2[46]);		if (ucp5 >= 5 && ucp5 <= 100) document.getElementById('ucp5').value=ucp5;
			ucp6=parseInt(FreshJR_nvram2[47]);		if (ucp6 >= 5 && ucp6 <= 100) document.getElementById('ucp6').value=ucp6;
			ucp7=parseInt(FreshJR_nvram2[48]);		if (ucp7 >= 5 && ucp7 <= 100) document.getElementById('ucp7').value=ucp7;
		}
	}
}

function FreshJR_mod_reset_down()
{
		document.getElementById('drp0').value=5;
		document.getElementById('drp1').value=20;
		document.getElementById('drp2').value=15;
		document.getElementById('drp3').value=10;
		document.getElementById('drp4').value=10;
		document.getElementById('drp5').value=30;
		document.getElementById('drp6').value=5;
		document.getElementById('drp7').value=5;
		
		document.getElementById('dcp0').value=100;
		document.getElementById('dcp1').value=100;
		document.getElementById('dcp2').value=100;
		document.getElementById('dcp3').value=100;
		document.getElementById('dcp4').value=100;
		document.getElementById('dcp5').value=100;
		document.getElementById('dcp6').value=100;
		document.getElementById('dcp7').value=100;
}

function FreshJR_mod_reset_up()
{
		document.getElementById('urp0').value=5;
		document.getElementById('urp1').value=20;
		document.getElementById('urp2').value=15;
		document.getElementById('urp3').value=30;
		document.getElementById('urp4').value=10;
		document.getElementById('urp5').value=10;
		document.getElementById('urp6').value=5;
		document.getElementById('urp7').value=5;
		
		document.getElementById('ucp0').value=100;
		document.getElementById('ucp1').value=100;
		document.getElementById('ucp2').value=100;
		document.getElementById('ucp3').value=100;
		document.getElementById('ucp4').value=100;
		document.getElementById('ucp5').value=100;
		document.getElementById('ucp6').value=100;
		document.getElementById('ucp7').value=100;
}

function FreshJR_mod_apply()
{
		var e1=document.getElementById('e1').value;			if (!(validate_ipv4(e1)))  e1="";
		var e2=document.getElementById('e2').value;			if (!(validate_ipv4(e2)))  e2="";
		var e4=document.getElementById('e4').value;			if (!(validate_port(e4)))  e4="";
		var e3=document.getElementById('e3').value;
		var e5=document.getElementById('e5').value;			if (!(validate_port(e5)))  e5="";
		var e6=document.getElementById('e6').value;			if (!(validate_mark(e6)))  e6="";
		var e7=document.getElementById('e7').value;
		
		var f1=document.getElementById('f1').value;			if (!(validate_ipv4(f1)))  f1="";
		var f2=document.getElementById('f2').value;			if (!(validate_ipv4(f2)))  f2="";
		var f3=document.getElementById('f3').value;
		var f4=document.getElementById('f4').value;			if (!(validate_port(f4)))  f4="";
		var f5=document.getElementById('f5').value;			if (!(validate_port(f5)))  f5="";
		var f6=document.getElementById('f6').value;			if (!(validate_mark(f6)))  f6="";
		var f7=document.getElementById('f7').value;
		
		var g1=document.getElementById('g1').value;			if (!(validate_ipv4(g1)))  g1="";
		var g2=document.getElementById('g2').value;			if (!(validate_ipv4(g2)))  g2="";
		var g3=document.getElementById('g3').value;
		var g4=document.getElementById('g4').value;			if (!(validate_port(g4)))  g4="";
		var g5=document.getElementById('g5').value;			if (!(validate_port(g5)))  g5="";
		var g6=document.getElementById('g6').value;			if (!(validate_mark(g6)))  g6="";
		var g7=document.getElementById('g7').value;
		
		var h1=document.getElementById('h1').value;			if (!(validate_ipv4(h1)))  h1="";
		var h2=document.getElementById('h2').value;			if (!(validate_ipv4(h2)))  h2="";
		var h3=document.getElementById('h3').value;
		var h4=document.getElementById('h4').value;			if (!(validate_port(h4)))  h4="";
		var h5=document.getElementById('h5').value;			if (!(validate_port(h5)))  h5="";
		var h6=document.getElementById('h6').value;			if (!(validate_mark(h6)))  h6="";
		var h7=document.getElementById('h7').value;
		
		var r1=document.getElementById('r1').value;			if (!(validate_mark(r1)))  r1="";
		var d1=document.getElementById('d1').value;	
		
		var r2=document.getElementById('r2').value;			if (!(validate_mark(r2)))  r2="";
		var d2=document.getElementById('d2').value;
		
		var r3=document.getElementById('r3').value;			if (!(validate_mark(r3)))  r3="";
		var d3=document.getElementById('d3').value;
		
		var r4=document.getElementById('r4').value;			if (!(validate_mark(r4)))  r4="";
		var d4=document.getElementById('d4').value;
		
		var gameCIDR=document.getElementById('gameCIDR').value;		if (!(validate_ipv4(gameCIDR)))  gameCIDR="";
		var ruleFLAG="FF"
		
		var drp0=document.getElementById('drp0').value;			if (!(validate_percent(drp0)))  drp0="5";
		var drp1=document.getElementById('drp1').value;			if (!(validate_percent(drp1)))  drp1="20";
		var drp2=document.getElementById('drp2').value;			if (!(validate_percent(drp2)))  drp2="15";
		var drp3=document.getElementById('drp3').value;			if (!(validate_percent(drp3)))  drp3="10";
		var drp4=document.getElementById('drp4').value;			if (!(validate_percent(drp4)))  drp4="10";
		var drp5=document.getElementById('drp5').value;			if (!(validate_percent(drp5)))  drp5="30";
		var drp6=document.getElementById('drp6').value;			if (!(validate_percent(drp6)))  drp6="5";
		var drp7=document.getElementById('drp7').value;			if (!(validate_percent(drp7)))  drp7="5";
		var dcp0=document.getElementById('dcp0').value;			if (!(validate_percent(dcp0)))  dcp0="5";
		var dcp1=document.getElementById('dcp1').value;			if (!(validate_percent(dcp1)))  dcp1="20";
		var dcp2=document.getElementById('dcp2').value;			if (!(validate_percent(dcp2)))  dcp2="15";
		var dcp3=document.getElementById('dcp3').value;			if (!(validate_percent(dcp3)))  dcp3="30";
		var dcp4=document.getElementById('dcp4').value;			if (!(validate_percent(dcp4)))  dcp4="10";
		var dcp5=document.getElementById('dcp5').value;			if (!(validate_percent(dcp5)))  dcp5="10";
		var dcp6=document.getElementById('dcp6').value;			if (!(validate_percent(dcp6)))  dcp6="5";
		var dcp7=document.getElementById('dcp7').value;			if (!(validate_percent(dcp7)))  dcp7="5";	
		var urp0=document.getElementById('urp0').value;			if (!(validate_percent(urp0)))  urp0="100";
		var urp1=document.getElementById('urp1').value;			if (!(validate_percent(urp1)))  urp1="100";
		var urp2=document.getElementById('urp2').value;			if (!(validate_percent(urp2)))  urp2="100";
		var urp3=document.getElementById('urp3').value;			if (!(validate_percent(urp3)))  urp3="100";
		var urp4=document.getElementById('urp4').value;			if (!(validate_percent(urp4)))  urp4="100";
		var urp5=document.getElementById('urp5').value;			if (!(validate_percent(urp5)))  urp5="100";
		var urp6=document.getElementById('urp6').value;			if (!(validate_percent(urp6)))  urp6="100";
		var urp7=document.getElementById('urp7').value;			if (!(validate_percent(urp7)))  urp7="100";
		var ucp0=document.getElementById('ucp0').value;			if (!(validate_percent(ucp0)))  ucp0="100";
		var ucp1=document.getElementById('ucp1').value;			if (!(validate_percent(ucp1)))  ucp0="100";
		var ucp2=document.getElementById('ucp2').value;			if (!(validate_percent(ucp2)))  ucp0="100";
		var ucp3=document.getElementById('ucp3').value;			if (!(validate_percent(ucp3)))  ucp0="100";
		var ucp4=document.getElementById('ucp4').value;			if (!(validate_percent(ucp4)))  ucp0="100";
		var ucp5=document.getElementById('ucp5').value;			if (!(validate_percent(ucp5)))  ucp0="100";
		var ucp6=document.getElementById('ucp6').value;			if (!(validate_percent(ucp6)))  ucp0="100";
		var ucp7=document.getElementById('ucp7').value;			if (!(validate_percent(ucp7)))  ucp0="100";

	var nvram1= e1 +";"+ e2 +";"+ e3 +";"+ e4 +";"+ e5 +";"+ e6 +";"+ e7 +">"+ 
				f1 +";"+ f2 +";"+ f3 +";"+ f4 +";"+ f5 +";"+ f6 +";"+ f7 +">"+ 
				g1 +";"+ g2 +";"+ g3 +";"+ g4 +";"+ g5 +";"+ g6 +";"+ g7;
				
	var nvram2= h1 +";"+ h2 +";"+ h3 +";"+ h4 +";"+ h5 +";"+ h6 +";"+ h7 +">"+ 
				r1 +";"+ d1 +">"+ 
				r2 +";"+ d2 +">"+ 
				r3 +";"+ d3 +">"+ 
				r4 +";"+ d4 +">"+ 
				gameCIDR +">"+ 
				ruleFLAG +">"+ 
				drp0 +";"+ drp1 +";"+ drp2 +";"+ drp3 +";"+ drp4 +";"+ drp5 +";"+ drp6 +";"+ drp7 +">"+ 
				dcp0 +";"+ dcp1 +";"+ dcp2 +";"+ dcp3 +";"+ dcp4 +";"+ dcp5 +";"+ dcp6 +";"+ dcp7 +">"+ 
				urp0 +";"+ urp1 +";"+ urp2 +";"+ urp3 +";"+ urp4 +";"+ urp5 +";"+ urp6 +";"+ urp7 +">"+ 
				ucp0 +";"+ ucp1 +";"+ ucp2 +";"+ ucp3 +";"+ ucp4 +";"+ ucp5 +";"+ ucp6 +";"+ ucp7;
	
	document.form.fb_comment.value = nvram1;
	document.form.fb_email_dbg.value = nvram2;
	document.form.action_script.value = "restart_qos;restart_firewall";
	document.form.submit();
}

function validate_ipv4(input)
{
	if (!(input))								 return 1;			//is blank

	input = input.replace(/^\!/,"");
	input = input.split(".");
	if (input.length != 4)			 		 			return false; //console.log("fail length");	
	for (var i = 0; i < input.length; i++)
	{
		if (i == 3 && /\//.test(input[3]) )
		{
			cidr = input[3].split("/")[1];
			if ( !( cidr >= 1 && cidr <= 32) )			return false; //console.log("fail cidr");
			input[3] = input[3].split("/")[0];
		}
		if(!(input[i] >= 0 && input[i] <= 255))			return false; //console.log("fail range");
	}
	
	return 1;
}

function validate_port(input)
{
	if (!(input))								 return 1;			//is blank
	
	input = input.replace(/^\!/,"");
	if (/[^0-9\:\,]/.test(input)) 					 	return false; //console.log("fail character");
	
	if ( input.includes(",") && input.includes(":") )	return false; //console.log("fail combination of delimiters");	
	
	if ( input.includes(":") )
	{
		split = input.split(":");
		if (split.length > 2 )							return false;	//console.log("fail quantity of delimiters");
		if (!(split[0] > 0 && split[0] <= 65535))		return false;	//console.log("fail port range XXXXX:");
		if (!(split[1] > 0 && split[1] <= 65535))		return false;	//console.log("fail port range"     :XXXXX);
		if ( split[0] > split[1] )						return false;	//console.log("fail not in ascending order")
	}
	else if ( input.includes(",") )
	{
		split = input.split(",");
		for (var i = 0; i < split.length; i++)
		{
			if (!(split[i] > 0 && split[i] <= 65535))	return false;			//console.log("fail port range (,) " + split[i] );
		}
	}
	else if (!(input > 0 && input <= 65535))			return false; //console.log("fail port range");
	return 1;
}

function validate_mark(input)
{
	if (!(input)) 								return 1;				//is blank
	
	if (input.length != 6 )								return false;	//console.log("fail length");
	if (input.substr(-4) == "****")
	{
		if ( /[^0-9a-fA-F]/.test(input.substr(0,2) )) 	return false;	//console.log("fail beg character");
	}
	else
	{
		if ( /[^0-9a-fA-F]/.test(input) ) 				return false;	//console.log("fail character");
	}
	return 1;

}

function validate_percent(input)
{
	if (!(input)) 										return false;	//cannot be blank
	if ( /[^0-9]/.test(input) ) 						return false;	//console.log("fail character");
	if ( input < 5 || input > 100) 						return false;	//console.log("fail range");
	return 1
}

</script>
</head>
<body onload="initial();">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get(" preferred_lang "); %>">
<input type="hidden" name="firmver" value="<% nvram_get(" firmver "); %>">
<input type="hidden" name="current_page" value="/QoS_Stats.asp">
<input type="hidden" name="next_page" value="/QoS_Stats.asp">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_script" value="">
<input type="hidden" name="action_wait" value="15">
<input type="hidden" name="flag" value="">
<input type="hidden" name="fb_comment" value="asd">
<input type="hidden" name="fb_email_dbg" value="zxc">
<table class="content" align="center" cellpadding="0" cellspacing="0">
<tr>
<td width="17">&nbsp;</td>
<td valign="top" width="202">
<div id="mainMenu"></div>
<div id="subMenu"></div>
</td>
<td valign="top">
<div id="tabMenu" class="submenuBlock"></div>
<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
<tr>
<td valign="top">
<table width="760px" border="0" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
<tbody bgcolor="#4D595D">
<tr>
<td valign="top">
<div class="formfonttitle" style="margin:10px 0px 10px 5px; display:inline-block;">Traffic classification</div>
<div id="FreshJR_mod_toggle" style="float:right; color:#FFCC00; display:inline-block; margin:5px; cursor:pointer;" onclick='FreshJR_mod_toggle()'>FreshJR Mod <small>(Customize)</small></div>
<div style="margin-bottom:10px" class="splitLine"></div>

<!-- FreshJR UI Start-->	
<div id="FreshJR_mod" style="display:none;">
<div style="display:inline-block; margin:0px 0px 10px 5px; font-size:14px; text-shadow: 1px 1px 0px black;"><b>QoS Modification</b></div>
<div style="display:inline-block; margin:-2px 5px 0px 0px; height:22px; width:136px; float:right; font-weight:bold;" class="titlebtn" onclick="FreshJR_mod_apply();"><p style="margin-left:10px;" align="center">Apply</p></div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" class="FormTable">		
<thead><td colspan="7">Iptable Rules (ipv4) </td></thead>
	<tbody>
		<tr>
			<th><a class="hintstyle" href="javascript:void(0);" onclick="overlib(ipsyntaxL, 500, 500);" onmouseout="nd();">Local  IP/CIDR</a></th>
			<th><a class="hintstyle" href="javascript:void(0);" onclick="overlib(ipsyntaxR, 500, 500);" onmouseout="nd();">Remote IP/CIDR</a></th>
			<th><a class="hintstyle" href="javascript:void(0);" onclick="overlib(protosyntax, 300, 500);" onmouseout="nd();">Protocol</a></th>
			<th><a class="hintstyle" href="javascript:void(0);" onclick="overlib(portsyntax, 300, 500);" onmouseout="nd();">Local  Port</a></th>
			<th><a class="hintstyle" href="javascript:void(0);" onclick="overlib(portsyntax, 300, 500);" onmouseout="nd();">Remote Port</a></th>
			<th><a class="hintstyle" href="javascript:void(0);" onclick="overlib(marksyntax, 500, 500);" onmouseout="nd();">Mark</a></th>
			<th><a class="hintstyle" href="javascript:void(0);" onclick="overlib(classsyntax, 300, 500);" onmouseout="nd();">Class</a></th>
		</tr>

		<tr>
			<td><input id="gameCIDR" onfocusout='validate_ipv4(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_15_table" maxlength="18" style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><input type="text" class="input_15_table" maxlength="18" style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly></td>
			<td><select class="input_option" style="width:55px;margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly><option>BOTH</option></select></td>
			<td><input type="text" class="input_12_table" maxlength="12" style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly></td>
			<td><input type="text" class="input_12_table" maxlength="12" style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" value="!80,443" readonly></td>
			<td><input type="text" class="input_6_table" maxlength="6"   style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" value="000000" readonly></td>
			<td><select class="input_option" style="width:125px; font-size:11.5px; margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly"><option value="UDP">Gaming</option></select></td>
		</tr>

		<tr>
			<td><input type="text" class="input_15_table" maxlength="18" style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly></td>
			<td><input type="text" class="input_15_table" maxlength="18" style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly></td>
			<td><select class="input_option" style="width:55px; margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly><option>UDP</option></select></td>
			<td><input type="text" class="input_12_table" maxlength="12" style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly></td>
			<td><input type="text" class="input_12_table" maxlength="12" style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" value="500,4500" readonly></td>
			<td><input type="text" class="input_6_table" maxlength="6"   style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly></td>
			<td><select class="input_option" style="width:125px; font-size:11.5px; margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly"><option value="UDP">VoIP</option></select></td>
		</tr>
		
		<tr>
			<td><input type="text" class="input_15_table" maxlength="18" style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly></td>
			<td><input type="text" class="input_15_table" maxlength="18" style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly></td>
			<td><select class="input_option" style="width:55px;margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly><option>UDP</option></select></td>
			<td><input type="text" class="input_12_table" maxlength="12" style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" value="16384:16415" readonly></td>
			<td><input type="text" class="input_12_table" maxlength="12" style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly></td>
			<td><input type="text" class="input_6_table" maxlength="6"   style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly></td>
			<td><select class="input_option" style="width:125px; font-size:11.5px; margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly"><option value="UDP">VoIP</option></select></td>
		</tr>
		
		<tr>
			<td><input type="text" class="input_15_table" maxlength="18" style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly></td>
			<td><input type="text" class="input_15_table" maxlength="18" style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly></td>
			<td><select class="input_option" style="width:55px;margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly><option>TCP</option></select></td>
			<td><input type="text" class="input_12_table" maxlength="12" style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly></td>
			<td><input type="text" class="input_12_table" maxlength="12" style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" value="119,563" readonly></td>
			<td><input type="text" class="input_6_table" maxlength="6"   style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly></td>
			<td><select class="input_option" style="width:125px; font-size:11.5px; margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly"><option value="UDP">File Downloads</option></select></td>
		</tr>

		<tr>
			<td><input type="text" class="input_15_table" maxlength="18" style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly></td>
			<td><input type="text" class="input_15_table" maxlength="18" style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly></td>
			<td><select class="input_option" style="width:55px;margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly><option>TCP</option></select></td>
			<td><input type="text" class="input_12_table" maxlength="12" style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly></td>
			<td><input type="text" class="input_12_table" maxlength="12" style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" value="80,443" readonly></td>
			<td><input type="text" class="input_6_table" maxlength="6"   style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" value="08****" readonly></td>
			<td><select class="input_option" style="width:125px; font-size:11.5px; margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly"><option value="UDP">Game Downloads</option></select></td>
		</tr>

		<tr>
			<td><input id="e1" onfocusout='validate_ipv4(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_15_table" maxlength="18" style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><input id="e2" onfocusout='validate_ipv4(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_15_table" maxlength="18" style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><select id="e3" class="input_option" style="width:55px;margin-left:-5px">
				<option value="both">BOTH</option>
				<option value="tcp">TCP</option>
				<option value="udp">UDP</option>
				</select></td>
			<td><input id="e4" onfocusout='validate_port(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_12_table" maxlength="16" style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><input id="e5" onfocusout='validate_port(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_12_table" maxlength="16" style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><input id="e6" onfocusout='validate_mark(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" maxlength="6"   style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><select id="e7" class="input_option" style="width:55px;width:125px; font-size:11.5px; margin-left:-5px">
					<option value="0">Net Control</option>
					<option value="3">VoIP</option>
					<option value="1">Gaming</option>
					<option value="6">Others</option>
					<option value="4">Web Surfing</option>
					<option value="2">Streaming</option>
					<option value="7">Game Downloads</option>
					<option value="5">File Downloads</option></select></td>
		</tr>
		
		<tr>
			<td><input id="f1" onfocusout='validate_ipv4(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_15_table" maxlength="18" style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><input id="f2" onfocusout='validate_ipv4(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_15_table" maxlength="18" style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><select id="f3" class="input_option" style="width:55px;margin-left:-5px">
				<option value="both">BOTH</option>
				<option value="tcp">TCP</option>
				<option value="udp">UDP</option>
				</select></td>
			<td><input id="f4" onfocusout='validate_port(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_12_table" maxlength="16" style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><input id="f5" onfocusout='validate_port(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_12_table" maxlength="16" style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><input id="f6" onfocusout='validate_mark(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" maxlength="6"   style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><select id="f7" class="input_option" style="width:55px;width:125px; font-size:11.5px; margin-left:-5px">
					<option value="0">Net Control</option>
					<option value="3">VoIP</option>
					<option value="1">Gaming</option>
					<option value="6">Others</option>
					<option value="4">Web Surfing</option>
					<option value="2">Streaming</option>
					<option value="7">Game Downloads</option>
					<option value="5">File Downloads</option></select></td>
		</tr>
		
		<tr>
			<td><input id="g1" onfocusout='validate_ipv4(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_15_table" maxlength="18" style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><input id="g2" onfocusout='validate_ipv4(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_15_table" maxlength="18" style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><select id="g3" class="input_option" style="width:55px;margin-left:-5px">
				<option value="both">BOTH</option>
				<option value="tcp">TCP</option>
				<option value="udp">UDP</option>
				</select></td>
			<td><input id="g4" onfocusout='validate_port(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_12_table" maxlength="16" style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><input id="g5" onfocusout='validate_port(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_12_table" maxlength="16" style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><input id="g6" onfocusout='validate_mark(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" maxlength="6"   style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><select id="g7" class="input_option" style="width:55px;width:125px; font-size:11.5px; margin-left:-5px">
					<option value="0">Net Control</option>
					<option value="3">VoIP</option>
					<option value="1">Gaming</option>
					<option value="6">Others</option>
					<option value="4">Web Surfing</option>
					<option value="2">Streaming</option>
					<option value="7">Game Downloads</option>
					<option value="5">File Downloads</option></select></td>
		</tr>
		
		<tr>
			<td><input id="h1" onfocusout='validate_ipv4(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_15_table" maxlength="18" style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><input id="h2" onfocusout='validate_ipv4(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_15_table" maxlength="18" style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><select id="h3" class="input_option" style="width:55px;margin-left:-5px">
				<option value="both">BOTH</option>
				<option value="tcp">TCP</option>
				<option value="udp">UDP</option>
				</select></td>
			<td><input id="h4" onfocusout='validate_port(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_12_table" maxlength="16" style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><input id="h5" onfocusout='validate_port(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_12_table" maxlength="16" style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><input id="h6" onfocusout='validate_mark(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" maxlength="6"   style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><select id="h7" class="input_option" style="width:55px;width:125px; font-size:11.5px; margin-left:-5px">
					<option value="0">Net Control</option>
					<option value="3">VoIP</option>
					<option value="1">Gaming</option>
					<option value="6">Others</option>
					<option value="4">Web Surfing</option>
					<option value="2">Streaming</option>
					<option value="7">Game Downloads</option>
					<option value="5">File Downloads</option></select></td>
		</tr>
	</tbody>
</table>

<table border="0" cellpadding="4" cellspacing="0" class="FormTable" style="width:100%; margin:10px auto 10px auto">		
<thead><td colspan="3">AppDB Redirection (traffic control)</td></thead>
	<tbody>
		<tr>
			<th style="width:auto">AppDB</th>
			<th style="width:10px">Mark</th>
			<th style="width:10px">Class</th>
		</tr>

		</tr>
			<td>Untracked </td>
			<td><input type="text" class="input_6_table" maxlength="6"  style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default"  value="000000"></td>
			<td><select class="input_option" style="width:125px; font-size:11.5px; margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly"><option>Others</option></select></td>
		</tr>
		
		</tr>
			<td>Snapchat </td>
			<td><input type="text" class="input_6_table" maxlength="6"  style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default"  value="00006B"></td>
			<td><select class="input_option" style="width:125px; font-size:11.5px; margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly"><option>Others</option></select></td>
		</tr>
		
		</tr>
			<td>Speedtest.net</td>
			<td><input type="text" class="input_6_table" maxlength="6"  style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default"  value="0D0007"></td>
			<td><select class="input_option" style="width:125px; font-size:11.5px; margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly"><option>File Downloads</option></select></td>
		</tr>
		
		</tr>
			<td>Google Play</td>
			<td><input type="text" class="input_6_table" maxlength="6"  style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default"  value="0D0086"></td>
			<td><select class="input_option" style="width:125px; font-size:11.5px; margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly"><option>File Downloads</option></select></td>
		</tr>
		
		</tr>
			<td>Apple AppStore </td>
			<td><input type="text" class="input_6_table" maxlength="6"  style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default"  value="0D00A0"></td>
			<td><select class="input_option" style="width:125px; font-size:11.5px; margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly"><option>File Downloads</option></select></td>
		</tr>
		
		
		</tr>
			<td>World Wide Web HTTP</td>
			<td><input type="text" class="input_6_table" maxlength="6"  style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default"  value="12003F"></td>
			<td><select class="input_option" style="width:125px; font-size:11.5px; margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly"><option>Web Surfing</option></select></td>
		</tr>

		</tr>
			<td>HTTP Protocol over TLS SSL + Misc</td>
			<td><input type="text" class="input_6_table" maxlength="6"  style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default"  value="13****"></td>
			<td><select class="input_option" style="width:125px; font-size:11.5px; margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly"><option>Web Surfing</option></select></td>
		</tr>
		
		</tr>
			<td>TLS SSL Connections + Misc </td>
			<td><input type="text" class="input_6_table" maxlength="6"  style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default"  value="14****"></td>
			<td><select class="input_option" style="width:125px; font-size:11.5px; margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly"><option>Web Surfing</option></select></td>
		</tr>
		
		</tr>
			<td>Advertisement </td>
			<td><input type="text" class="input_6_table" maxlength="6"  style="margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default"  value="1A****"></td>
			<td><select class="input_option" style="width:125px; font-size:11.5px; margin-left:-5px; background-color: rgb(204, 204, 204); cursor:default" readonly"><option>Web Surfing</option></select></td>
		</tr>
		
		</tr>
			<td></td>
			<td><input  id="r1" onfocusout='validate_mark(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" maxlength="6"   style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><select id="d1" class="input_option" style="width:55px;width:125px; font-size:11.5px; margin-left:-5px">
					<option value="0">Net Control</option>
					<option value="3">VoIP</option>
					<option value="1">Gaming</option>
					<option value="6">Others</option>
					<option value="4">Web Surfing</option>
					<option value="2">Streaming</option>
					<option value="7">Game Downloads</option>
					<option value="5">File Downloads</option></select></td>
		</tr>
		</tr>
			<td></td>
			<td><input  id="r2" onfocusout='validate_mark(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" maxlength="6"   style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><select id="d2" class="input_option" style="width:55px;width:125px; font-size:11.5px; margin-left:-5px">
					<option value="0">Net Control</option>
					<option value="3">VoIP</option>
					<option value="1">Gaming</option>
					<option value="6">Others</option>
					<option value="4">Web Surfing</option>
					<option value="2">Streaming</option>
					<option value="7">Game Downloads</option>
					<option value="5">File Downloads</option></select></td>
		</tr>
		</tr>
			<td></td>
			<td><input  id="r3" onfocusout='validate_mark(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" maxlength="6"   style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><select id="d3" class="input_option" style="width:55px;width:125px; font-size:11.5px; margin-left:-5px">
					<option value="0">Net Control</option>
					<option value="3">VoIP</option>
					<option value="1">Gaming</option>
					<option value="6">Others</option>
					<option value="4">Web Surfing</option>
					<option value="2">Streaming</option>
					<option value="7">Game Downloads</option>
					<option value="5">File Downloads</option></select></td>
		</tr>
		</tr>
			<td></td>
			<td><input  id="r4" onfocusout='validate_mark(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" maxlength="6"   style="margin-left:-5px" autocomplete="off" autocorrect="off" autocapitalize="off"></td>
			<td><select id="d4" class="input_option" style="width:55px;width:125px; font-size:11.5px; margin-left:-5px">
					<option value="0">Net Control</option>
					<option value="3">VoIP</option>
					<option value="1">Gaming</option>
					<option value="6">Others</option>
					<option value="4">Web Surfing</option>
					<option value="2">Streaming</option>
					<option value="7">Game Downloads</option>
					<option value="5">File Downloads</option></select></td>
		</tr>
	</tbody>
</table>

<table border="0" cellpadding="0" cellspacing="0" class="FormTable" style="float:left; width:350px; display:inline-table; margin: 10px auto 10px auto">		
<thead><td colspan="3">Download Bandwidth<small style="float:right; font-weight:normal; margin-right:10px; cursor:pointer;" onclick='FreshJR_mod_reset_down()'>Reset</small></td></thead>
	<tbody>
		<tr>
			<th style="min-width:125px;">Class</th>
			<th style="min-width:90px;">Minimum Reserved Bandwidth</th>
			<th style="min-width:90px;">Maximum Allowed Bandwidth</th>
		</tr>
		<tr>
			<th>Net Control</th>
			<td><input id="drp0" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="2" autocomplete="off" autocorrect="off" autocapitalize="off" value="5"> % </td>
			<td><input id="dcp0" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="3" autocomplete="off" autocorrect="off" autocapitalize="off" value="100"> % </td>
		</tr>
		<tr>
			<th>VoIP</th>
			<td><input id="drp1" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="2" autocomplete="off" autocorrect="off" autocapitalize="off" value="20"> % </td>
			<td><input id="dcp1" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="3" autocomplete="off" autocorrect="off" autocapitalize="off" value="100"> % </td>
		</tr>
		<tr>
			<th>Gaming</th>
			<td><input id="drp2" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="2" autocomplete="off" autocorrect="off" autocapitalize="off" value="15"> % </td>
			<td><input id="dcp2" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="3" autocomplete="off" autocorrect="off" autocapitalize="off" value="100"> % </td>
		</tr>
		<tr>
			<th>Others</th>
			<td><input id="drp3" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="2" autocomplete="off" autocorrect="off" autocapitalize="off" value="10"> % </td>
			<td><input id="dcp3" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="3" autocomplete="off" autocorrect="off" autocapitalize="off" value="100"> % </td>
		</tr>
		<tr>
			<th>Web Surfing</th>
			<td><input id="drp4" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="2" autocomplete="off" autocorrect="off" autocapitalize="off" value="10"> % </td>
			<td><input id="dcp4" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="3" autocomplete="off" autocorrect="off" autocapitalize="off" value="100"> % </td>
		</tr>
		<tr>
			<th>Streaming</th>
			<td><input id="drp5" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="2" autocomplete="off" autocorrect="off" autocapitalize="off" value="30"> % </td>
			<td><input id="dcp5" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="3" autocomplete="off" autocorrect="off" autocapitalize="off" value="100"> % </td>
		</tr>
		<tr>
			<th>Game Downloads</th>
			<td><input id="drp6" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="2" autocomplete="off" autocorrect="off" autocapitalize="off" value="5"> % </td>
			<td><input id="dcp6" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="3" autocomplete="off" autocorrect="off" autocapitalize="off" value="100"> % </td>
		</tr>
		<tr>
			<th>File Downloads</th>
			<td><input id="drp7" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="2" autocomplete="off" autocorrect="off" autocapitalize="off" value="5"> % </td>
			<td><input id="dcp7" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="3" autocomplete="off" autocorrect="off" autocapitalize="off" value="100"> % </td>
		</tr>
	</tbody>
</table>

<table border="0" cellpadding="0" cellspacing="0" class="FormTable" style="float:right; width:350px; display:inline-table; margin-top:10px; margin: 10px auto 10px auto">	
<thead><td colspan="3">Upload Bandwidth<small style="float:right; font-weight:normal; margin-right:10px; cursor:pointer;" onclick='FreshJR_mod_reset_up()'>Reset</small></td></thead>
	<tbody>
		<tr>
			<th style="min-width:125px;">Class</th>
			<th style="min-width:90px;">Minimum Reserved Bandwidth</th>
			<th style="min-width:90px;">Maximum Allowed Bandwidth</th>
		</tr>
		<tr>
			<th>Net Control</th>
			<td><input id="urp0" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="2" autocomplete="off" autocorrect="off" autocapitalize="off" value="5"> % </td>
			<td><input id="ucp0" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="3" autocomplete="off" autocorrect="off" autocapitalize="off" value="100"> % </td>
		</tr>
		<tr>
			<th>VoIP</th>
			<td><input id="urp1" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="2" autocomplete="off" autocorrect="off" autocapitalize="off" value="20"> % </td>
			<td><input id="ucp1" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="3" autocomplete="off" autocorrect="off" autocapitalize="off" value="100"> % </td>
		</tr>
		<tr>
			<th>Gaming</th>
			<td><input id="urp2" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="2" autocomplete="off" autocorrect="off" autocapitalize="off" value="15"> % </td>
			<td><input id="ucp2" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="3" autocomplete="off" autocorrect="off" autocapitalize="off" value="100"> % </td>
		</tr>
		<tr>
			<th>Others</th>
			<td><input id="urp3" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="2" autocomplete="off" autocorrect="off" autocapitalize="off" value="30"> % </td>
			<td><input id="ucp3" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="3" autocomplete="off" autocorrect="off" autocapitalize="off" value="100"> % </td>
		</tr>
		<tr>
			<th>Web Surfing</th>
			<td><input id="urp4" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="2" autocomplete="off" autocorrect="off" autocapitalize="off" value="10"> % </td>
			<td><input id="ucp4" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="3" autocomplete="off" autocorrect="off" autocapitalize="off" value="100"> % </td>
		</tr>
		<tr>
			<th>Streaming</th>
			<td><input id="urp5" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="2" autocomplete="off" autocorrect="off" autocapitalize="off" value="10"> % </td>
			<td><input id="ucp5" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="3" autocomplete="off" autocorrect="off" autocapitalize="off" value="100"> % </td>
		</tr>
		<tr>
			<th>Game Downloads</th>
			<td><input id="urp6" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="2" autocomplete="off" autocorrect="off" autocapitalize="off" value="5"> % </td>
			<td><input id="ucp6" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="3" autocomplete="off" autocorrect="off" autocapitalize="off" value="100"> % </td>
		</tr>
		<tr>
			<th>File Downloads</th>
			<td><input id="urp7" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="2" autocomplete="off" autocorrect="off" autocapitalize="off" value="5"> % </td>
			<td><input id="ucp7" onfocusout='validate_percent(this.value)?this.style.removeProperty("background-color"):this.style.backgroundColor="#A86262"' type="text" class="input_6_table" style="height:18px;"  maxlength="3" autocomplete="off" autocorrect="off" autocapitalize="off" value="100"> % </td>
		</tr>
	</tbody>
</table>
<p style="clear:left;clear:right;"></p>
</div>
<!-- FreshJR UI END-->
<table id="refresh_data" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="margin-top:10px;">
<tr>
<th>Automatically refresh data every</th>
<td>
<select name="refreshrate" class="input_option" onchange="refreshRate = this.value; get_data();" id="refreshrate">
<option value="0">No refresh</option>
<option value="3" selected>3 seconds</option>
<option value="5">5 seconds</option>
<option value="10">10 seconds</option>
</select>
</td>
</tr>
</table>
<br>
<div id="limiter_notice" style="display:none;font-size:125%;color:#FFCC00;">Note: Statistics not available in Bandwidth Limiter mode.</div>
<div id="no_qos_notice" style="display:none;font-size:125%;color:#FFCC00;">Note: QoS is not enabled.</div>
<div id="tqos_notice" style="display:none;font-size:125%;color:#FFCC00;">Note: Traditional QoS only classifies uploaded traffic.</div>
<table>
<tr id="dl_tr">
<td style="padding-right:50px;font-size:125%;color:#FFCC00;">
<div>Download</div>
<canvas id="pie_chart_dl" width="200" height="200"></canvas>
</td>
<td><span id="legend_dl"></span></td>
</tr>
<tr style="height:50px;">
<td colspan="2">&nbsp;</td>
</tr>
<tr id="ul_tr">
<td style="padding-right:50px;font-size:125%;color:#FFCC00;">
<div>Upload</div>
<canvas id="pie_chart_ul" width="200" height="200"></canvas>
</td>
<td><span id="legend_ul"></span></td>
</tr>
</table>
<br>
<!-- FreshJR Device Filter Start-->
<table cellpadding="4" class="tableApi_table" style="margin-bottom:10px;" id="filter_device">
<tbody>
<tr>
<th width="100px">Filter By Device:</th>
<td bgcolor="#475a5f">
<select name="devicefilter" id="devicefilter" style="min-width: 300px; margin:2px 0px 2px 5px" width=100px class="input_option" onchange="deviceFilter = this.value; get_data();">
<option value="*" > </option>
</select>
</td>
</tr>
</tbody>
</table>
<!-- FreshJR Device Filter End-->
<!-- FreshJR Connection Table Start-->

<table cellpadding="4" class="tableApi_table" id="tracked_connections">
<thead>
   <td colspan="6">Tracked connections</td>
</thead>
<tbody id="tableContainer">
   <tr class="row_title">
      <th id="tProto" width="5%"  style="cursor: pointer;">Proto</th>
      <th id="tLip"   width="28%" style="cursor: pointer;">Source</th>
      <th id="tRip"   width="6%"  style="cursor: pointer;">SPort</th>
      <th id="tLport" width="28%" style="cursor: pointer;">Destination</th>
      <th id="tRport" width="6%"  style="cursor: pointer;">DPort</th>
      <th id="tLabel" width="27%"  style="cursor: pointer;">Application</th>
   </tr>
</tbody>
</table>

<!-- FreshJR Connection Table End-->
</td>
</tr>
</tbody>
</table>
</td>
</tr>
</table>
</td>
<td width="10" align="center" valign="top">&nbsp;</td>
</tr>
</table>
</form>
<div id="footer"></div>
</body>
</html>