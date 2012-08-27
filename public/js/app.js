(function () {
	
	$('#copy-code').zclip({
		path:'js/ZeroClipboard.swf',
		copy:function(){
			return $('input#embed-code').val();
		},

		 afterCopy:function(){
			$(this).text('Copied').addClass('btn-success');
		}
	})

	$('form').submit(function (e) {
		e.preventDefault();
		$.ajax({
			url: 'getcode',
			dataType: 'json',
			data: $('form').serialize(),
			success: function (data) {
				console.log(data);
			}
		})
		return false;
	});

})($)