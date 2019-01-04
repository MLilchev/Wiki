function validateForm() {
	// Check username
	var x = document.forms["myForm"]["username"].value;
	var y = document.forms["myForm"]["password"].value;
	if (x==null || x==""){
		alert("Name must be filled out!");
		return false;
	} else if (x.length < 5) {
		alert("Name must be at least 5 characters long!");
		return false;
	}

	//Check password
	if (y==null || y==""){
		alert("Password must be filled out!");
		return false;
	} else if (y.length < 5) {
		alert("Password must be at least 5 characters long!");
		return false;
	}

	return true;

	}

