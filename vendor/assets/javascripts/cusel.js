function cuSel(params) {
							
	jQuery(params.changedEl).each(
	function(num)
	{
	var chEl = jQuery(this),
		chElWid = chEl.outerWidth(), 
		chElClass = chEl.prop("class"), 
		chElId = chEl.prop("id"), 
		chElName = chEl.prop("name"), 
		defaultVal = chEl.val(), 
		activeOpt = chEl.find("option[value='"+defaultVal+"']").eq(0),
		defaultText = activeOpt.text(), 
		disabledSel = chEl.prop("disabled"), 
		scrollArrows = params.scrollArrows,
		chElOnChange = chEl.prop("onchange"),
		chElTab = chEl.prop("tabindex"),
		chElMultiple = chEl.prop("multiple");
		
		if(!chElId || chElMultiple)	return false; 
		
		if(!disabledSel)
		{
			classDisCuselText = "", 
			classDisCusel=""; 
		}
		else
		{
			classDisCuselText = "classDisCuselLabel";
			classDisCusel="classDisCusel";
		}
		
		if(scrollArrows)
		{
			classDisCusel+=" cuselScrollArrows";
		}
			
		activeOpt.addClass("cuselActive");  
	
	var optionStr = chEl.html(), 

		
	
	
	spanStr = optionStr.replace(/option/ig,"span").replace(/value=/ig,"val="); 
	
	
	if($.browser.msie && parseInt($.browser.version) < 9)
	{
		var pattern = /(val=)(.*?)(>)/g;
		spanStr = spanStr.replace(pattern, "$1'$2'$3");
	}

	
	
	var cuselFrame = '<div class="cusel '+chElClass+' '+classDisCusel+'"'+
					' id=cuselFrame-'+chElId+
					' style="width:'+chElWid+'px"'+
					' tabindex="'+chElTab+'"'+
					'>'+
					'<div class="cuselFrameRight"></div>'+
					'<div class="cuselText">'+defaultText+'</div>'+
					'<div class="cusel-scroll-wrap"><div class="cusel-scroll-pane" id="cusel-scroll-'+chElId+'">'+
					spanStr+
					'</div></div>'+
					'<input type="hidden" id="'+chElId+'" name="'+chElName+'" value="'+defaultVal+'" />'+
					'</div>';
					
					
	
	chEl.replaceWith(cuselFrame);
	

	if(chElOnChange) jQuery("#"+chElId).bind('change',chElOnChange);

	
	var newSel = jQuery("#cuselFrame-"+chElId),
		arrSpan = newSel.find("span"),
		defaultHeight;
		
		if(!arrSpan.eq(0).text())
		{
			defaultHeight = arrSpan.eq(1).innerHeight();
			arrSpan.eq(0).css("height", arrSpan.eq(1).height());
		} 
		else
		{
			defaultHeight = arrSpan.eq(0).innerHeight();
		}
		
	
	if(arrSpan.length>params.visRows)
	{
		newSel.find(".cusel-scroll-wrap").eq(0)
			.css({height: defaultHeight*params.visRows+"px", display : "none", visibility: "visible" })
			.children(".cusel-scroll-pane").css("height",defaultHeight*params.visRows+"px");
	}
	else
	{
		newSel.find(".cusel-scroll-wrap").eq(0)
			.css({display : "none", visibility: "visible" });
	}
	

	
	var arrAddTags = jQuery("#cusel-scroll-"+chElId).find("span[addTags]"),
		lenAddTags = arrAddTags.length;
		
		for(i=0;i<lenAddTags;i++) arrAddTags.eq(i)
										.append(arrAddTags.eq(i).attr("addTags"))
										.removeAttr("addTags");
										
	cuselEvents();
	
	});


function cuselEvents() {
jQuery("html").unbind("click");

jQuery("html").click(
	function(e)
	{

		var clicked = jQuery(e.target),
			clickedId = clicked.attr("id"),
			clickedClass = clicked.prop("class");
			
		
		if((clickedClass.indexOf("cuselText")!=-1 || clickedClass.indexOf("cuselFrameRight")!=-1) && clicked.parent().prop("class").indexOf("classDisCusel")==-1)
		{
			var cuselWrap = clicked.parent().find(".cusel-scroll-wrap").eq(0);
			
			
			cuselShowList(cuselWrap);
		}
		
		else if(clickedClass.indexOf("cusel")!=-1 && clickedClass.indexOf("classDisCusel")==-1 && clicked.is("div"))
		{
	
			var cuselWrap = clicked.find(".cusel-scroll-wrap").eq(0);
			
			
			cuselShowList(cuselWrap);
	
		}
		
		
		else if(clicked.is(".cusel-scroll-wrap span") && clickedClass.indexOf("cuselActive")==-1)
		{
			var clickedVal;
			(clicked.attr("val") == undefined) ? clickedVal=clicked.text() : clickedVal=clicked.attr("val");
			clicked
				.parents(".cusel-scroll-wrap").find(".cuselActive").eq(0).removeClass("cuselActive")
				.end().parents(".cusel-scroll-wrap")
				.next().val(clickedVal)
				.end().prev().text(clicked.text())
				.end().css("display","none")
				.parent(".cusel").removeClass("cuselOpen");
			clicked.addClass("cuselActive");
			clicked.parents(".cusel-scroll-wrap").find(".cuselOptHover").removeClass("cuselOptHover");
			if(clickedClass.indexOf("cuselActive")==-1)	clicked.parents(".cusel").find(".cusel-scroll-wrap").eq(0).next("input").change(); // чтобы срабатывал onchange
		}
		
		else if(clicked.parents(".cusel-scroll-wrap").is("div"))
		{
			return;
		}
		
		
		else
		{
			jQuery(".cusel-scroll-wrap")
				.css("display","none")
				.parent(".cusel").removeClass("cuselOpen");
		}
		

		
	});

jQuery(".cusel").unbind("keydown"); 

jQuery(".cusel").keydown(
function(event)
{
	
	
	var key, keyChar;
		
	if(window.event) key=window.event.keyCode;
	else if (event) key=event.which;
	
	if(key==null || key==0 || key==9) return true;
	
	if(jQuery(this).prop("class").indexOf("classDisCusel")!=-1) return false;
		
	
	if(key==40)
	{
		var cuselOptHover = jQuery(this).find(".cuselOptHover").eq(0);
		if(!cuselOptHover.is("span")) var cuselActive = jQuery(this).find(".cuselActive").eq(0);
		else var cuselActive = cuselOptHover;
		var cuselActiveNext = cuselActive.next();
			
		if(cuselActiveNext.is("span"))
		{
			jQuery(this)
				.find(".cuselText").eq(0).text(cuselActiveNext.text());
			cuselActive.removeClass("cuselOptHover");
			cuselActiveNext.addClass("cuselOptHover");
			
			$(this).find("input").eq(0).val(cuselActiveNext.attr("val"));
					
			
			cuselScrollToCurent($(this).find(".cusel-scroll-wrap").eq(0));
			
			return false;
		}
		else return false;
	}
	
	
	if(key==38)
	{
		var cuselOptHover = $(this).find(".cuselOptHover").eq(0);
		if(!cuselOptHover.is("span")) var cuselActive = $(this).find(".cuselActive").eq(0);
		else var cuselActive = cuselOptHover;
		cuselActivePrev = cuselActive.prev();
			
		if(cuselActivePrev.is("span"))
		{
			$(this)
				.find(".cuselText").eq(0).text(cuselActivePrev.text());
			cuselActive.removeClass("cuselOptHover");
			cuselActivePrev.addClass("cuselOptHover");
			
			$(this).find("input").eq(0).val(cuselActivePrev.attr("val"));
			

			cuselScrollToCurent($(this).find(".cusel-scroll-wrap").eq(0));
			
			return false;
		}
		else return false;
	}
	
	
	if(key==27)
	{
		var cuselActiveText = $(this).find(".cuselActive").eq(0).text();
		$(this)
			.removeClass("cuselOpen")
			.find(".cusel-scroll-wrap").eq(0).css("display","none")
			.end().find(".cuselOptHover").eq(0).removeClass("cuselOptHover");
		$(this).find(".cuselText").eq(0).text(cuselActiveText);

	}
	
	
	if(key==13)
	{
		
		var cuselHover = $(this).find(".cuselOptHover").eq(0);
		if(cuselHover.is("span"))
		{
			$(this).find(".cuselActive").removeClass("cuselActive");
			cuselHover.addClass("cuselActive");
		}
		else var cuselHoverVal = $(this).find(".cuselActive").attr("val");
		
		$(this)
			.removeClass("cuselOpen")
			.find(".cusel-scroll-wrap").eq(0).css("display","none")
			.end().find(".cuselOptHover").eq(0).removeClass("cuselOptHover");
		$(this).find("input").eq(0).change();
	}
	
	
	if(key==32 && $.browser.opera)
	{
		var cuselWrap = $(this).find(".cusel-scroll-wrap").eq(0);
		
		
		cuselShowList(cuselWrap);
	}
		
	if($.browser.opera) return false; 

});


var arr = [];
jQuery(".cusel").keypress(function(event)
{
	var key, keyChar;
		
	if(window.event) key=window.event.keyCode;
	else if (event) key=event.which;
	
	if(key==null || key==0 || key==9) return true;
	
	if(jQuery(this).prop("class").indexOf("classDisCusel")!=-1) return false;
	
	var o = this;
	arr.push(event);
	clearTimeout(jQuery.data(this, 'timer'));
	var wait = setTimeout(function() { handlingEvent() }, 500);
	jQuery(this).data('timer', wait);
	function handlingEvent()
	{
		var charKey = [];
		for (var iK in arr)
		{
			if(window.event)charKey[iK]=arr[iK].keyCode;
			else if(arr[iK])charKey[iK]=arr[iK].which;
			charKey[iK]=String.fromCharCode(charKey[iK]).toUpperCase();
		}
		var arrOption=jQuery(o).find("span"),colArrOption=arrOption.length,i,letter;
		for(i=0;i<colArrOption;i++)
		{
			var match = true;
			for (var iter in arr)
			{
				letter=arrOption.eq(i).text().charAt(iter).toUpperCase();
				if (letter!=charKey[iter])
				{
					match=false;
				}
			}
			if(match)
			{
				jQuery(o).find(".cuselOptHover").removeClass("cuselOptHover").end().find("span").eq(i).addClass("cuselOptHover").end().end().find(".cuselText").eq(0).text(arrOption.eq(i).text());
			
			
			cuselScrollToCurent($(o).find(".cusel-scroll-wrap").eq(0));
			arr = arr.splice;
			arr = [];
			break;
			return true;
			}
		}
		arr = arr.splice;
		arr = [];
	}
	if(jQuery.browser.opera && window.event.keyCode!=9) return false;
});
								
}
	
jQuery(".cusel").focus(
function()
{
	jQuery(this).addClass("cuselFocus");
	
});

jQuery(".cusel").blur(
function()
{
	jQuery(this).removeClass("cuselFocus");
});

jQuery(".cusel").hover(
function()
{
	jQuery(this).addClass("cuselFocus");
},
function()
{
	jQuery(this).removeClass("cuselFocus");
});

}

function cuSelRefresh(params)
{
	

	var arrRefreshEl = params.refreshEl.split(","),
		lenArr = arrRefreshEl.length,
		i;
	
	for(i=0;i<lenArr;i++)
	{
		var refreshScroll = jQuery(arrRefreshEl[i]).parents(".cusel").find(".cusel-scroll-wrap").eq(0);
		refreshScroll.find(".cusel-scroll-pane").jScrollPaneRemoveCusel();
		refreshScroll.css({visibility: "hidden", display : "block"});
	
		var	arrSpan = refreshScroll.find("span"),
			defaultHeight = arrSpan.eq(0).outerHeight();
		
	
		if(arrSpan.length>params.visRows)
		{
			refreshScroll
				.css({height: defaultHeight*params.visRows+"px", display : "none", visibility: "visible" })
				.children(".cusel-scroll-pane").css("height",defaultHeight*params.visRows+"px");
		}
		else
		{
			refreshScroll
				.css({display : "none", visibility: "visible" });
		}
	}
	
}

function cuselShowList(cuselWrap)
{
	var cuselMain = cuselWrap.parent(".cusel");
	
	
	if(cuselWrap.css("display")=="none")
	{
		$(".cusel-scroll-wrap").css("display","none");
		
		cuselMain.addClass("cuselOpen");
		cuselWrap.css("display","block");
		var cuselArrows = false;
		if(cuselMain.prop("class").indexOf("cuselScrollArrows")!=-1) cuselArrows=true;
		if(!cuselWrap.find(".jScrollPaneContainer").eq(0).is("div"))
		{
			cuselWrap.find("div").eq(0).jScrollPaneCusel({showArrows:cuselArrows});
		}
				
		
		cuselScrollToCurent(cuselWrap);
		}
		else
		{
			cuselWrap.css("display","none");
			cuselMain.removeClass("cuselOpen");
		}
}



function cuselScrollToCurent(cuselWrap)
{
	var cuselScrollEl = null;
	if(cuselWrap.find(".cuselOptHover").eq(0).is("span")) cuselScrollEl = cuselWrap.find(".cuselOptHover").eq(0);
	else if(cuselWrap.find(".cuselActive").eq(0).is("span")) cuselScrollEl = cuselWrap.find(".cuselActive").eq(0);

	if(cuselWrap.find(".jScrollPaneTrack").eq(0).is("div") && cuselScrollEl)
	{
		
		var posCurrentOpt = cuselScrollEl.position(),
			idScrollWrap = cuselWrap.find(".cusel-scroll-pane").eq(0).attr("id");

		jQuery("#"+idScrollWrap)[0].scrollTo(posCurrentOpt.top);	
	
	}	
}
