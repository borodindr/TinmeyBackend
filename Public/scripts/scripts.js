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

	// caption: function (fancybox, carousel, slide) {
	//     let caption = slide.caption;

	//     if (slide.type === "image") {
	//       	caption = (caption.length ? caption + "<br />" : "") + '<a target="_blank" href="' + slide.src + '">Download image</a>';
	//     }

	//     return caption + '<a href="https://www.behance.net/gallery/107899639/Illustration-and-Book-Cover-Design-Young-Adult" target="_blank">Behance</a>';
 //  	},
});