Fancybox.bind('[data-fancybox="gallery"]', {
	dragToClose: false,

	Toolbar: false,
	closeButton: "top",

	Thumbs: false,

	Carousel: {
	    // Enable dots
	    Dots: false,
	},

	Image: {
		zoom: false,
	},

	on: {
		initCarousel: (fancybox) => {
			const slide = fancybox.Carousel.slides[fancybox.Carousel.page];

			fancybox.$container.style.setProperty(
				"--bg-image",
				`url("${slide.$thumb.src}")`
			);
		},
		"Carousel.change": (fancybox, carousel, to, from) => {
			const slide = carousel.slides[to];

			fancybox.$container.style.setProperty(
				"--bg-image",
				`url("${slide.$thumb.src}")`
			);
		},
	},

	caption: function (fancybox, carousel, slide) {
	    let caption = slide.caption;

	    let title = caption;
	    let body = slide.captionBody;

	    let linkNameStart = body.indexOf("[");
	    let linkNameEnd = body.indexOf("]");
	    let linkUrlStart = body.indexOf("(");
	    let linkUrlEnd = body.indexOf(")");

	    while (
	    	linkNameStart >= 0 && 
	    	linkNameEnd >= 0 && 
	    	linkUrlStart >= 0 &&
	    	linkUrlEnd >= 0 &&
	    	linkNameStart < linkNameEnd &&
	    	linkNameEnd == linkUrlStart - 1 &&
	    	linkUrlStart < linkUrlEnd
	    ) {
	    	let linkName = body.substring(linkNameStart + 1, linkNameEnd);
	    	let linkUrl = body.substring(linkUrlStart + 1, linkUrlEnd);
	    	if (linkName == "") {
	    		linkName = linkUrl
	    	}
	    	let htmlLink = "<a href=\"" + linkUrl + "\" target=\"_blank\">" + linkName + "</a>";
	    	let markdownLink = body.substring(linkNameStart, linkUrlEnd + 1);
	    	body = body.replace(markdownLink, htmlLink);

	    	linkNameStart = body.indexOf("[");
	    	linkNameEnd = body.indexOf("]");
	    	linkUrlStart = body.indexOf("(");
	    	linkUrlEnd = body.indexOf(")");
	    }

	    caption = "<h3>" + title + "</h3>" + "<p>" + body + "</p>";

	    return caption;
  	},
});