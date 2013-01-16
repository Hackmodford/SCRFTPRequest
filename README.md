SCRFTPRequest
=============
>Formerly S7FTPRequest

***
*SCRFTPRequest was created by [Alaksiej Nieścieraŭ](https://github.com/nesterow). All code and most of this readme was written by him.*

This project was inspired by a marvelous lib that I'm using in all my apps that involve network interactions (I can hardly remember one without any) [ASIHTTPRequest](https://github.com/pokeb/asi-http-request).

This is the product of composing together [ASIHTTPRequest](https://github.com/pokeb/asi-http-request) design solutions and [SimpleFTPSample](http://developer.apple.com/library/ios/#samplecode/SimpleFTPSample/Introduction/Intro.html) techniques.

#Features
***
* Upload and Create directory operations. More to come soon. 
* Based on `CFNetwork`, but provides friendly Objective-C API with delegates to handle progress and status of the request. 
* Inherits from `NSOperation`. 
* Supports authentication. 
* ARC ready

#Using the Component
***
Since `SCRFTPRequest` is a `NSOperation`, you can easily add it to `NSOperationQueue` for asynchronous invokation. However, it is possible to use `SCRFTPRequest` as a plain `NSObject`. Here are some basic instructions. (I'm going to add more details in time.)

The request's delegate must implement the `SCRFTPRequestDelegate` protocol.

### Delegate

```
@protocol SCRFTPRequestDelegate <NSObject>

/** Called on the delegate when the request completes successfully. */
- (void)ftpRequestDidFinish:(SCRFTPRequest *)request;
/** Called on the delegate when the request fails. */
- (void)ftpRequest:(SCRFTPRequest *)request didFailWithError:(NSError *)error;

@optional
/** Called on the delegate when the transfer is about to start. */
- (void)ftpRequestWillStart:(SCRFTPRequest *)request;
/** Called on the delegate when the status of the request instance changed. */
- (void)ftpRequestDidChangeStatus:(SCRFTPRequest *)request;
/** Called on the delegate when some amount of bytes were transferred. */
- (void)ftpRequest:(SCRFTPRequest *)request didWriteBytes:(NSUInteger)bytesWritten;

@end
```

###Upload

Initialization

```
SCRFTPRequest *ftpRequest = [[SCRFTPRequest alloc] initWithURL:[NSURL URLWithString:@"ftp://192.168.1.101/"] 
toUploadFile:[[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"]];

ftpRequest.username = @"testuser"; 
ftpRequest.password = @"testuser"; 

// Specify a custom upload file name (optional)
ftpRequest.customUploadFileName = @"App_Info.plist";

// The delegate must implement the SCRFTPRequestDelegate protocol
ftpRequest.delegate = self;  

[ftpRequest startRequest];
```

Implement the callbacks (they are performed on the main thread, so you can invoke your UI components safely):

```
// Required delegate methods
- (void)ftpRequestDidFinish:(SCRFTPRequest *)request { 

	NSLog(@"Upload finished."); 
}

- (void)ftpRequest:(SCRFTPRequest *)request didFailWithError:(NSError *)error {

	NSLog(@"Upload failed: %@", [error localizedDescription]); 
}

// Optional delegate methods
- (void)ftpRequestWillStart:(SCRFTPRequest *)request { 

	NSLog(@"Will transfer %d bytes.", request.fileSize); 
}

- (void)ftpRequest:(SCRFTPRequest *)request didWriteBytes:(NSUInteger)bytesWritten { 

	NSLog(@"Transferred: %d", bytesWritten); 
}

- (void)ftpRequest:(SCRFTPRequest *)request didChangeStatus:(SCRFTPRequestStatus)status {

	switch (status) { 
	case SCRFTPRequestStatusOpenNetworkConnection: 
		NSLog(@"Opened connection."); 
		break; 
	case SCRFTPRequestStatusReadingFromStream: 
		NSLog(@"Reading from stream..."); 
		break; 
	case SCRFTPRequestStatusWritingToStream: 
		NSLog(@"Writing to stream..."); 
		break; 
	case SCRFTPRequestStatusClosedNetworkConnection: 
		NSLog(@"Closed connection."); 
		break; 
	case SCRFTPRequestStatusError: 
		NSLog(@"Error occurred."); 
		break; 
	} 
}
```
Cancel the operation this way

```
[ftpRequest cancelRequest];
```

###Create directory
To create a directory you will need practically the same infrastructure except for the initialization code may look like this:

```
SCRFTPRequest *ftpRequest = [[SCRFTPRequest alloc] initWithURL:[NSURL URLWithString:@"ftp://192.168.1.101/"] 
toCreateDirectory:@"SCRFTPRequest"];
  
ftpRequest.username = @"testuser";
ftpRequest.password = @"testuser";
	
ftpRequest.delegate = self;
	
[ftpRequest startRequest];
```
