#SCRFTPRequest
######Simple to use FTP component for iPhone and Mac OS X
=============
This project was inspired by a marvelous lib that I'm using in all my apps that involve network interactions (I can hardly remember one without any) [ASIHTTPRequest](https://github.com/pokeb/asi-http-request).

This is the product of composing together [ASIHTTPRequest](https://github.com/pokeb/asi-http-request) design solutions and [SimpleFTPSample](http://developer.apple.com/library/ios/#samplecode/SimpleFTPSample/Introduction/Intro.html) techniques.

#Features
* Item Upload and Create directory operations. More to come soon. 
* Item Based on CFNetwork, but provides friendly Objective C API with delegates to handle progress and status of the request. 
* Item Inherits from NSOperation. 
* Item Supports authentication. 

#Using the Component

Since SCRFTPRequest is a NSOperation, you can easily add it to NSOperationQueue for asynchronous invokation. However, it is possible to use SCRFTPRequest as a plain NSObject. Here are some basic instructions. (I'm going to add more details in time.)

##Upload

Initialization

```objective-c
SCRFTPRequest *ftpRequest = [[SCRFTPRequest alloc] initWithURL: 
[NSURL URLWithString:@"ftp://192.168.1.101/"] 
toUploadFile:[[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"]];

ftpRequest.username = @"testuser"; 
ftpRequest.password = @"testuser"; 

ftpRequest.delegate = self; 
ftpRequest.didFinishSelector = @selector(uploadFinished:); 
ftpRequest.didFailSelector = @selector(uploadFailed:); 
ftpRequest.willStartSelector = @selector(uploadWillStart:); 
ftpRequest.didChangeStatusSelector = @selector(requestStatusChanged:); 
ftpRequest.bytesWrittenSelector = @selector(uploadBytesWritten:); 

[ftpRequest startRequest];
```

Implement the callbacks (they are performed on the main thread, so you can invoke your UI components safely):

```objective-c
- (void)uploadFinished:(SCRFTPRequest *)request { 

NSLog(@"Upload finished."); 
[request release]; 
}

- (void)uploadFailed:(SCRFTPRequest *)request {

NSLog(@"Upload failed: %@", [request.error localizedDescription]); 
[request release]; 
}

- (void)uploadWillStart:(SCRFTPRequest *)request { 

NSLog(@"Will transfer %d bytes.", request.fileSize); 
}

- (void)uploadBytesWritten:(SCRFTPRequest *)request { 

NSLog(@"Transferred: %d", request.bytesWritten); 
}

- (void)requestStatusChanged:(SCRFTPRequest *)request {

switch (request.status) { 
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

```objective-c

[ftpRequest cancelRequest];
```

###Create directory
To create a directory you will need practically the same infrastructure except for the initialization code may look like this:

```objective-c

SCRFTPRequest *ftpRequest = [[SCRFTPRequest alloc] initWithURL:
[NSURL URLWithString:@"ftp://192.168.1.101/"]
toCreateDirectory:@"SCRFTPRequest"];
  
ftpRequest.username = @"testuser";
ftpRequest.password = @"testuser";
	
ftpRequest.delegate = self;
ftpRequest.didFinishSelector = @selector(createFinished:);
ftpRequest.didFailSelector = @selector(createFailed:);
ftpRequest.willStartSelector = @selector(createWillStart:);
ftpRequest.didChangeStatusSelector = @selector(requestStatusChanged:);
	
[ftpRequest startRequest];

```