
// Processing requests to send notifications for motion detection
Parse.Cloud.define("processMotionEvent", function(request, response) {
  var user = request.user;
  var message = request.params.message;
  var sendingDeviceID = request.params.sendingDeviceID;

  // Validate the message text.
  // For example make sure it is under 140 characters
  if (message.length > 140) {
  // Truncate and add a ...
    message = message.substring(0, 137) + "...";
  }

  // Send the push.
  // Find devices associated with the recipient user
  var pushQuery = new Parse.Query(Parse.Installation);
  pushQuery.equalTo("user", user);
  pushQuery.notEqualTo("deviceID", sendingDeviceID);
 
  // Send the push notification to results of the query
  Parse.Push.send({
    where: pushQuery,
    expiration_interval: 60*60*24*2,
    data: {
      alert: message,
      sound: "default"
    }
  }).then(function() {
      response.success("Push was sent successfully.")
  }, function(error) {
      response.error("Push failed to send with error: " + error.message);
  });
});

// Processing requests to send notifications for face detections
Parse.Cloud.define("processFaceDetectionEvent", function(request, response) {
  var user = request.user;
  var message = request.params.message;
  var sendingDeviceID = request.params.sendingDeviceID;
  var eventImageID = request.params.eventImageID;

  // Validate the message text.
  // For example make sure it is under 140 characters
  if (message.length > 140) {
  // Truncate and add a ...
    message = message.substring(0, 137) + "...";
  }

  // Send the push.
  // Find devices associated with the recipient user
  var pushQuery = new Parse.Query(Parse.Installation);
  pushQuery.equalTo("user", user);
  pushQuery.notEqualTo("deviceID", sendingDeviceID);
 
  // Send the push notification to results of the query
  Parse.Push.send({
    where: pushQuery,
    expiration_interval: 60*60*24*2,
    data: {
      alert: message, 
      sound: "default",
      p: eventImageID
    }
  }).then(function() {
      response.success("Push was sent successfully.")
  }, function(error) {
      response.error("Push failed to send with error: " + error.message);
  });
});

// Get Installations for a particular user
Parse.Cloud.define("getInstallationsForUser", function(request, response) {
  Parse.Cloud.useMasterKey();
  var user = request.user;
  var query = new Parse.Query("_Installation");

  query.equalTo("user", user);
  query.ascending("deviceName");
  query.find({
    success: function(results) {
      response.success(results);
    }, 
    error: function() {
      response.error("Failed to get Installations");
    }
  });
});

// Processing requests to disable a camera
Parse.Cloud.define("processDisableCommand", function(request, response) {
  var user = request.user;
  var message = request.params.message;
  var disableDeviceID = request.params.disableDeviceID;

  // Send the push.
  // Find devices associated with the recipient user
  var pushQuery = new Parse.Query(Parse.Installation);
  pushQuery.equalTo("user", user);
  pushQuery.equalTo("deviceID", disableDeviceID);
 
  // Send the push notification to results of the query
  Parse.Push.send({
    where: pushQuery,
    expiration_interval: 60*60*24*2,
    data: {
      alert: message,
      disable: "1",
      sound: "default"
    }
  }).then(function() {
      response.success("Push was sent successfully.")
  }, function(error) {
      response.error("Push failed to send with error: " + error.message);
  });
});

