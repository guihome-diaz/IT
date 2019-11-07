function map_mapel() {

	/** Dataset to display */
	var data = {
		"2007": {
			"areas": {
				"CN": { "attrs": { "fill": "#fff" }, },
				"FR": {
					"value": "2007-12 Val de loire",
					"href": "#",
					"tooltip": {
						"content": "<span style=\"font-weight:bold;\">France</span><br>2007-12"
					}
				},
				"CH": {
					"value": "2007-12 Geneve",
					"href": "#",
					"tooltip": {
						"content": "<span style=\"font-weight:bold;\">Switzerland</span><br />2007-12"
					}
				},
			},
			"plots": {
				"paris": {
					"value": 1448389,
					"tooltip": {
						"content": "<span style=\"font-weight:bold;\">Paris</span><br />Population: 1448389"
					}
				}
			}
		},
		"2008": {
			"areas": {
				"FR": {
					"value": "2008-04",
					"href": "#",
					"tooltip": {
						"content": "<span style=\"font-weight:bold;\">France</span><br /> 2008-04"
					}
				},
				"CN": {
					"value": "2008-11",							
					"attrs": {
						"fill": "#e59866 "
					}, 
					"attrsHover": {
						"fill": "#a4e100"
					},
					"href": "#",
					"tooltip": {
						"content": "<span style=\"font-weight:bold;\">China</span><br />2008"
					}
				}
			},
			"plots": {
				"paris": {
					"value": 1257410,
					"tooltip": {
						"content": "<span style=\"font-weight:bold;\">Paris</span><br />"
					}
				}
			}
		}
	};

	// Default plots params
	var plots = {
		"paris": {
			"type": "circle",
			"size": 7,
			"latitude": 48.86,
			"longitude": 2.3444,
			"text": {
				"position": "left",
				"content": "Paris"
			},
			"href": "#"
		}
	};

	// Knob initialisation (for selecting a year)
	$(".knob").knob({
		release: function (value) {
			$(".world").trigger('update', [{
				mapOptions: data[value],
				animDuration: 300
			}]);
		}
	});

	/** Map layout initialisation */
	$world = $(".world");
	$world.mapael({
		map: {
			/** map name must match one of the JS file that will be imported in the page.
			  *		ex: <script src="./resources/maps/world_countries.min.js"></script>
			  * ==> name: "world_countries",
			  */
			name: "world_countries",
			//name: "european_union",
			defaultArea: {
				attrs: {
					/** Default countries color, when not selected */
					fill: "#fff",
					stroke: "#232323",
					"stroke-width": 0.3
				}
			},
			defaultPlot: {
				text: {
					attrs: {
						fill: "#5dade2 ",
						"font-weight": "normal"
					},
					attrsHover: {
						fill: "#fff",
						"font-weight": "bold"
					}
				}
			}
			, zoom: {
				enabled: true
				, step: 0.25
				, maxLevel: 20
			}
		},
		plots: $.extend(true, {}, data[2007]['plots'], plots),
		areas: data[2007]['areas']
	});
}