SCRFtpRequest
=============

#Simple to use FTP component for iPhone and Mac OS X

This project was inspired by a marvelous lib that I'm using in all my apps that involve network interactions (I can hardly remember one without any): ASIHTTPRequest.

This is the product of composing together ASIHTTPRequest design solutions and SimpleFTPSample techniques.

FeaturesUpload and Create directory operations. More to come soon. Based on CFNetwork, but provides friendly Objective C API with delegates to handle progress and status of the request. Inherits from NSOperation. Supports authentication. Using the ComponentSince S7FTPRequest is a NSOperation, you can easily add it to NSOperationQueue for asynchronous invokation. However, it is possible to use S7FTPRequest as a plain NSObject. Here are some basic instructions. (I'm going to add more details in time.)

##Upload Initialization

```objective-c

S7FTPRequest *ftpRequest = [[S7FTPRequest alloc] initWithURL: 
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

[ftpRequest startRequest];Implement the callbacks (they are performed on the main thread, so you can invoke your UI components safely):

- (void)uploadFinished:(S7FTPRequest *)request { 

NSLog(@"Upload finished."); 
[request release]; 
}

- (void)uploadFailed:(S7FTPRequest *)request {

NSLog(@"Upload failed: %@", [request.error localizedDescription]); 
[request release]; 
}

- (void)uploadWillStart:(S7FTPRequest *)request { 

NSLog(@"Will transfer %d bytes.", request.fileSize); 
}

- (void)uploadBytesWritten:(S7FTPRequest *)request { 

NSLog(@"Transferred: %d", request.bytesWritten); 
}

- (void)requestStatusChanged:(S7FTPRequest *)request {

switch (request.status) { 
case S7FTPRequestStatusOpenNetworkConnection: 
NSLog(@"Opened connection."); 
break; 
case S7FTPRequestStatusReadingFromStream: 
NSLog(@"Reading from stream..."); 
break; 
case S7FTPRequestStatusWritingToStream: 
NSLog(@"Writing to stream..."); 
break; 
case S7FTPRequestStatusClosedNetworkConnection: 
NSLog(@"Closed connection."); 
break; 
case S7FTPRequestStatusError: 
NSLog(@"Error occurred."); 
break; 
} 
}
```
###Cancel Operation

```objective-c

[ftpRequest cancelRequest];
```
That's easy.

###Create directory
To create a directory you will need practically the same infrastructure except for the initialization code may look like this:

```objective-c

S7FTPRequest *ftpRequest = [[S7FTPRequest alloc] initWithURL: 
[NSURL URLWithString:@"ftp://192.168.1.101/"] 
toCreateDirectory:@"S7FTPRequest"]; 

ftpRequest.username = @"testuser"; 
ftpRequest.password = @"testuser"; 

ftpRequest.delegate = self; 
ftpRequest.didFinishSelector = @selector(createFinished:); 
ftpRequest.didFailSelector = @selector(createFailed:); 
ftpRequest.willStartSelector = @selector(createWillStart:); 
ftpRequest.didChangeStatusSelector = @selector(requestStatusChanged:); 

[ftpRequest startRequest];

```

###SimpleFTPSample.

```objective-c
S7FTPRequest *ftpRequest = [[S7FTPRequest alloc] initWithURL: [NSURL URLWithString:@"ftp://192.168.1.101/"] toUploadFile:[[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"]];

ftpRequest.username = @"testuser"; 
ftpRequest.password = @"testuser"; 

ftpRequest.delegate = self; 
ftpRequest.didFinishSelector = @selector(uploadFinished:); 
ftpRequest.didFailSelector = @selector(uploadFailed:); 
ftpRequest.willStartSelector = @selector(uploadWillStart:); 
ftpRequest.didChangeStatusSelector = @selector(requestStatusChanged:); 
ftpRequest.bytesWrittenSelector = @selector(uploadBytesWritten:); 

[ftpRequest startRequest];

- (void)uploadFinished:(S7FTPRequest *)request { 

NSLog(@"upload finished."); 
[request release]; 
}

- (void)uploadFailed:(S7FTPRequest *)request {

NSLog(@"upload failed: %@", [request.error localizedDescription]); 
[request release]; 
}

- (void)uploadWillStart:(S7FTPRequest *)request { 

NSLog(@"uploading bytes.", request.fileSize); 
}

- (void)uploadBytesWritten:(S7FTPRequest *)request { 

NSLog(@"Bytes written: %d", request.bytesWritten); 
}

- (void)requestStatusChanged:(S7FTPRequest *)request {

switch (request.status) { 
case S7FTPRequestStatusOpenNetworkConnection: 
NSLog(@"opened network connection"); 
break; 
case S7FTPRequestStatusReadingFromStream: 
NSLog(@"reading from stream"); 
break; 
case S7FTPRequestStatusWritingToStream: 
NSLog(@"writing to stream"); 
break; 
case S7FTPRequestStatusClosedNetworkConnection: 
NSLog(@"closed connection."); 
break; 
case S7FTPRequestStatusError: 
NSLog(@"error."); 
break; 
} 
}

```

```objective-c

[ftpRequest cancelRequest];

S7FTPRequest *ftpRequest = [[S7FTPRequest alloc] initWithURL: 
[NSURL URLWithString:@"ftp://192.168.1.101/"] 
toCreateDirectory:@"S7FTPRequest"]; 

ftpRequest.username = @"testuser"; 
ftpRequest.password = @"testuser"; 

ftpRequest.delegate = self; 
ftpRequest.didFinishSelector = @selector(createFinished:); 
ftpRequest.didFailSelector = @selector(createFailed:); 
ftpRequest.willStartSelector = @selector(createWillStart:); 
ftpRequest.didChangeStatusSelector = @selector(requestStatusChanged:); 

[ftpRequest startRequest];

```