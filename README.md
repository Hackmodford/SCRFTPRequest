SCRFtpRequest
=============

Simple to use FTP component for iPhone and Mac OS X

This project was inspired by a marvelous lib that I'm using in all my apps that involve network interactions (I can hardly remember one without any): ASIHTTPRequest.

This is the product of composing together ASIHTTPRequest design solutions and SimpleFTPSample techniques.

FeaturesUpload and Create directory operations. More to come soon. Based on CFNetwork, but provides friendly Objective C API with delegates to handle progress and status of the request. Inherits from NSOperation. Supports authentication. Using the ComponentSince S7FTPRequest is a NSOperation, you can easily add it to NSOperationQueue for asynchronous invokation. However, it is possible to use S7FTPRequest as a plain NSObject. Here are some basic instructions. (I'm going to add more details in time.)

UploadInitialization:

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
}To cancel the operation this way:

[ftpRequest cancelRequest];That's easy.

Create directoryTo create a directory you will need practically the same infrastructure except for the initialization code may look like this:

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

[ftpRequest startRequest];BielaruskajaГэты праект быў інспіраваны найцудоўнейшай лібай, якую я ўжываю ўва ўсіх маіх апліках, каторыя ўтрымоўваюць сеткавыя ўзаемадзеянні (наўрад ці я ўзгадаю хаця-б адзін, які-б не меў гэтакіх): ASIHTTPRequest.

Гэта прадукт спалучэння дызайну паводле ASIHTTPRequest і тэхнік SimpleFTPSample.

МажлівасціАперацыі запампоўкі і стварэння дырэкторыі. Астатнія на падыходзе. Базуецца на CFNetwork, але прадастаўляе прыязны Objective C API з дэлегатамі, каб апрацоўваць прагрэс ды стан запыту. Спадкаемца NSOperation. Падтрымоўвае аўтэнтыфікацыю. Ужыванне кампанентуS7FTPRequest ёсць NSOperation, таму вы ўлёгкую можаце дадаваць яго ў NSOperationQueue дзеля асінхронавых выклікаў. Адылі, S7FTPRequest мажліва ўжываць і як звычайны NSObject. Вось некаторыя базавыя інструкцыі. (З цягам часу я ўдасканалю гэтыя інструкцыі.)

ЗапампоўкаІніцыялізацыя:

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

[ftpRequest startRequest];Рэалізуем колбэкі (яны выконваюцца ў галоўным трэдзе, таму адтуль вы можаце спакойна звяртацца да вашых UI-кампанентаў):

- (void)uploadFinished:(S7FTPRequest *)request { 

NSLog(@"Запампоўка завершаная."); 
[request release]; 
}

- (void)uploadFailed:(S7FTPRequest *)request {

NSLog(@"Памылка пры запампоўцы: %@", [request.error localizedDescription]); 
[request release]; 
}

- (void)uploadWillStart:(S7FTPRequest *)request { 

NSLog(@"Перадасць %d байтаў.", request.fileSize); 
}

- (void)uploadBytesWritten:(S7FTPRequest *)request { 

NSLog(@"Перададзена: %d", request.bytesWritten); 
}

- (void)requestStatusChanged:(S7FTPRequest *)request {

switch (request.status) { 
case S7FTPRequestStatusOpenNetworkConnection: 
NSLog(@"Утварыў злучэнне."); 
break; 
case S7FTPRequestStatusReadingFromStream: 
NSLog(@"Чытае з струмяню..."); 
break; 
case S7FTPRequestStatusWritingToStream: 
NSLog(@"Піша ў струмень..."); 
break; 
case S7FTPRequestStatusClosedNetworkConnection: 
NSLog(@"Закрыў злучэнне."); 
break; 
case S7FTPRequestStatusError: 
NSLog(@"З'явілася памылка."); 
break; 
} 
}Скасаваць аперацыю можна наступным чынам:

[ftpRequest cancelRequest];Зусім проста.

Стварэнне новай тэчкіКаб стварыць дырэкторыю, спатрэбіцца практычна тая-ж самая інфраструктура, за выняткам хіба коду ініцыялізацыі, які можа выглядаць так:

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