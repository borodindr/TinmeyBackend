Fancybox.bind('[data-fancybox="gallery"]', {
	dragToClose: false,

	Toolbar: false,
	closeButton: "top",

	Thumbs: false,

	Carousel: {
	    // Enable dots
	    Dots: true,
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
});