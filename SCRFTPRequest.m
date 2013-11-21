//
//  SCRFTPRequest.m
//  SCRFtpClient
//
//  Created by Aleks Nesterow on 10/28/09.
//  aleks.nesterow@gmail.com
//	
//	Inspired by http://allseeing-i.com/ASIHTTPRequest/
//	Was using code samples from http://developer.apple.com/iphone/library/samplecode/SimpleFTPSample/index.html
//	and http://developer.apple.com/mac/library/samplecode/CFFTPSample/index.html
//  
//  Copyright © 2009, 7touch Group, Inc.
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//  * Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//  * Neither the name of the 7touchGroup, Inc. nor the
//  names of its contributors may be used to endorse or promote products
//  derived from this software without specific prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY 7touchGroup, Inc. "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL 7touchGroup, Inc. BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//  

#import "SCRFTPRequest.h"

NSString *const SCRFTPRequestErrorDomain = @"SCRFTPRequestErrorDomain";

static NSError *SCRFTPRequestTimedOutError;
static NSError *SCRFTPAuthenticationError;
static NSError *SCRFTPRequestCancelledError;
static NSError *SCRFTPUnableToCreateRequestError;

static NSOperationQueue *sharedRequestQueue = nil;

@interface SCRFTPRequest (/* Private */)
<NSStreamDelegate>
{
	BOOL _complete;
	
	/* State */
	UInt8 _buffer[kSCRFTPRequestBufferSize];
	UInt32 _bufferOffset;
	UInt32 _bufferLimit;
}

@property (nonatomic, strong) NSOutputStream *writeStream;
@property (nonatomic, strong) NSInputStream *readStream;
@property (nonatomic, strong) NSDate *timeOutDate;
@property (nonatomic, strong) NSRecursiveLock *cancelledLock;

@end

@implementation SCRFTPRequest

static inline void performOnMainThread(void (^block)()) {
    [[NSOperationQueue mainQueue] addOperations:@[[NSBlockOperation blockOperationWithBlock:block]]
                              waitUntilFinished:![NSThread isMainThread]];
}

- (void)setStatus:(SCRFTPRequestStatus)status {
	
	if (_status != status) {
		_status = status;
		if ([self.delegate respondsToSelector:@selector(ftpRequest:didChangeStatus:)]) {
            performOnMainThread(^{
                [self.delegate ftpRequest:self didChangeStatus:_status];
            });
		}
	}
}

#pragma mark init / dealloc

+ (void)initialize {
	
	if (self == [SCRFTPRequest class]) {
		
		SCRFTPRequestTimedOutError = [NSError errorWithDomain:SCRFTPRequestErrorDomain
														 code:SCRFTPRequestTimedOutErrorType
													 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
															   NSLocalizedString(@"The request timed out.", @""),
															   NSLocalizedDescriptionKey, nil]];
		SCRFTPAuthenticationError = [NSError errorWithDomain:SCRFTPRequestErrorDomain
														code:SCRFTPAuthenticationErrorType
													userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
															  NSLocalizedString(@"Authentication needed.", @""),
															  NSLocalizedDescriptionKey, nil]];
		SCRFTPRequestCancelledError = [NSError errorWithDomain:SCRFTPRequestErrorDomain
														  code:SCRFTPRequestCancelledErrorType
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																NSLocalizedString(@"The request was cancelled.", @""),
																NSLocalizedDescriptionKey, nil]];
		SCRFTPUnableToCreateRequestError = [NSError errorWithDomain:SCRFTPRequestErrorDomain
															   code:SCRFTPUnableToCreateRequestErrorType
														   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																	 NSLocalizedString(@"Unable to create request (bad url?)", @""),
																	 NSLocalizedDescriptionKey,nil]];
	}
	
	[super initialize];
}

- (id)init {
	
	if (self = [super init]) {
		[self initializeComponentWithURL:nil operation:SCRFTPRequestOperationDownload];
	}
	
	return self;
}

- (id)initWithURL:(NSURL *)ftpURL toDownloadFile:(NSString *)filePath {
	
	if (self = [super init]) {
		[self initializeComponentWithURL:ftpURL operation:SCRFTPRequestOperationDownload];
		self.filePath = filePath;
	}
	
	return self;
}

- (id)initWithURL:(NSURL *)ftpURL toUploadFile:(NSString *)filePath {
	
	if (self = [super init]) {
		[self initializeComponentWithURL:ftpURL operation:SCRFTPRequestOperationUpload];
		self.filePath = filePath;
	}
	
	return self;
}

- (id)initWithURL:(NSURL *)ftpURL toCreateDirectory:(NSString *)directoryName {
	
	if (self = [super init]) {
		[self initializeComponentWithURL:ftpURL operation:SCRFTPRequestOperationCreateDirectory];
		self.directoryName = directoryName;
	}
	
	return self;
}

- (void)initializeComponentWithURL:(NSURL *)ftpURL operation:(SCRFTPRequestOperation)operation {
	
	self.ftpURL = ftpURL;
	self.operation = operation;
	self.timeOutSeconds = 10;
	self.cancelledLock = [[NSRecursiveLock alloc] init];
}

+ (id)requestWithURL:(NSURL *)ftpURL toDownloadFile:(NSString *)filePath {
	
	return [[self alloc] initWithURL:ftpURL toDownloadFile:filePath];
}

+ (id)requestWithURL:(NSURL *)ftpURL toUploadFile:(NSString *)filePath {
	
	return [[self alloc] initWithURL:ftpURL toUploadFile:filePath];
}

+ (id)requestWithURL:(NSURL *)ftpURL toCreateDirectory:(NSString *)directoryName {
	
	return [[self alloc] initWithURL:ftpURL toCreateDirectory:directoryName];
}

#pragma mark Request logic

- (void)applyCredentials {
	
	if (self.username) {
		if (![self.writeStream setProperty:self.username forKey:(id)kCFStreamPropertyFTPUserName]) {
			[self failWithError:
			 [self constructErrorWithCode:SCRFTPInternalErrorWhileApplyingCredentialsType
								  message:[NSString stringWithFormat:
										   NSLocalizedString(@"Cannot apply the username \"%@\" to the FTP stream.", @""),
										   self.username]]];
			return;
		}
		if (![self.writeStream setProperty:self.password forKey:(id)kCFStreamPropertyFTPPassword]) {
			[self failWithError:
			 [self constructErrorWithCode:SCRFTPInternalErrorWhileApplyingCredentialsType
								  message:[NSString stringWithFormat:
										   NSLocalizedString(@"Cannot apply the password \"%@\" to the FTP stream.", @""),
										   self.password]]];
			return;
		}
	}
}

- (void)cancel {
	
	[[self cancelledLock] lock];
	
	/* Request may already be complete. */
	if ([self isComplete] || [self isCancelled]) {
		return;
	}
	
	[self cancelRequest];
	
	[[self cancelledLock] unlock];
	
	/* Must tell the operation to cancel after we unlock, as this request might be dealloced and then NSLock will log an error. */
	[super cancel];
}

- (void)main {
	
	@autoreleasepool {
        
        [[self cancelledLock] lock];
        
        [self startRequest];
        [self resetTimeout];
        
        [[self cancelledLock] unlock];
        
        /* Main loop */
        while (![self isCancelled] && ![self isComplete]) {
            
            [[self cancelledLock] lock];
            
            /* Do we need to timeout? */
            if ([[self timeOutDate] timeIntervalSinceNow] < 0) {
                [self failWithError:SCRFTPRequestTimedOutError];
                break;
            }
            
            [[self cancelledLock] unlock];
            
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[self timeOutDate]];
        }
    
}
}

- (void)resetTimeout
{
	[self setTimeOutDate:[NSDate dateWithTimeIntervalSinceNow:[self timeOutSeconds]]];
}

- (void)cancelRequest {
	
	[self failWithError:SCRFTPRequestCancelledError];
}

- (void)startRequest {
	
	_complete = NO;
	_fileSize = 0;
	_bytesWritten = 0;
	_status = SCRFTPRequestStatusNone;
	
	switch (self.operation) {
		case SCRFTPRequestOperationUpload:
			[self startUploadRequest];
			break;
		case SCRFTPRequestOperationCreateDirectory:
			[self startCreateDirectoryRequest];
			break;
        case SCRFTPRequestOperationDownload:
            break;
	}
}

- (void)startAsynchronous
{
	[[SCRFTPRequest sharedRequestQueue] addOperation:self];
}


- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
	
	//[[self cancelledLock] lock];
    NSAssert(stream == self.writeStream, @"Stream should be equal to write stream.");
	
	[self resetTimeout];
	
	switch (self.operation) {
		case SCRFTPRequestOperationUpload:
			[self handleUploadEvent:eventCode];
			break;
		case SCRFTPRequestOperationCreateDirectory:
			[self handleCreateDirectoryEvent:eventCode];
			break;
        case SCRFTPRequestOperationDownload:
            break;
	}
	
	//[[self cancelledLock] unlock];
}

#pragma mark Upload logic

- (void)startUploadRequest {
	
	if (!self.ftpURL || !self.filePath) {
		[self failWithError:SCRFTPUnableToCreateRequestError];
		return;
	}
	
	CFStringRef fileName = CFBridgingRetain(self.customUploadFileName ? self.customUploadFileName : [self.filePath lastPathComponent]);
    
	if (!fileName) {
		[self failWithError:
		 [self constructErrorWithCode:SCRFTPInternalErrorWhileBuildingRequestType
							  message:[NSString stringWithFormat:
									   NSLocalizedString(@"Unable to retrieve file name from file located at %@", @""),
									   self.filePath]]];
		return;
	}

	CFURLRef uploadUrl = CFURLCreateCopyAppendingPathComponent(kCFAllocatorDefault, (__bridge CFURLRef)self.ftpURL, fileName, false);
    CFRelease(fileName);
	if (!uploadUrl) {
		[self failWithError:[self constructErrorWithCode:SCRFTPInternalErrorWhileBuildingRequestType
												 message:NSLocalizedString(@"Unable to build URL to upload.", @"")]];
		return;
	}
	
	NSError *attributesError = nil;
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:&attributesError];
	if (attributesError) {
		[self failWithError:attributesError];
        CFRelease(uploadUrl); //added this line to fix analyze warning saying that uploadURL wasn't being release...
		return;
	} else {
		_fileSize = [fileAttributes fileSize];
		if ([self.delegate respondsToSelector:@selector(ftpRequestWillStart:)]) {
            performOnMainThread(^{
                [self.delegate ftpRequestWillStart:self];
            });
		}
	}
	
	self.readStream = [NSInputStream inputStreamWithFileAtPath:self.filePath];
	if (!self.readStream) {
		[self failWithError:
		 [self constructErrorWithCode:SCRFTPUnableToCreateRequestErrorType
							  message:[NSString stringWithFormat:
									   NSLocalizedString(@"Cannot start reading the file located at %@ (bad path?).", @""),
									   self.filePath]]];
        CFRelease(uploadUrl); //added this line to fix analyze warning saying that uploadURL wasn't being release...
		return;
	}
	
	[self.readStream open];
	
	CFWriteStreamRef uploadStream = CFWriteStreamCreateWithFTPURL(NULL, uploadUrl);
	if (!uploadStream) {
		[self failWithError:
		 [self constructErrorWithCode:SCRFTPUnableToCreateRequestErrorType
							  message:[NSString stringWithFormat:
									   NSLocalizedString(@"Cannot open FTP connection to %@", @""),
									   CFBridgingRelease(uploadUrl)]]];
		return;
	}
	CFRelease(uploadUrl);
	
	self.writeStream = CFBridgingRelease(uploadStream);
	[self applyCredentials];
	self.writeStream.delegate = self;
	[self.writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self.writeStream open];
}

- (void)handleUploadEvent:(NSStreamEvent)eventCode {
	
	switch (eventCode) {
        case NSStreamEventOpenCompleted: {
			[self setStatus:SCRFTPRequestStatusOpenNetworkConnection];
        } break;
        case NSStreamEventHasSpaceAvailable: {
			
            /* If we don't have any data buffered, go read the next chunk of data. */
            if (_bufferOffset == _bufferLimit) {
				
				[self setStatus:SCRFTPRequestStatusReadingFromStream];
                NSInteger bytesRead = [self.readStream read:_buffer maxLength:kSCRFTPRequestBufferSize];
                if (bytesRead == -1) {
					[self failWithError:
					 [self constructErrorWithCode:SCRFTPConnectionFailureErrorType
										  message:[NSString stringWithFormat:
												   NSLocalizedString(@"Cannot continue reading the file at %@", @""),
												   self.filePath]]];
					return;
				} else if (bytesRead == 0) {
					[self requestFinished];
					return;
                } else {
                    _bufferOffset = 0;
                    _bufferLimit = (UInt32)bytesRead;
                }
            }
            
            /* If we're not out of data completely, send the next chunk. */
            
            if (_bufferOffset != _bufferLimit) {
				
                _bytesWritten = [self.writeStream write:&_buffer[_bufferOffset] maxLength:_bufferLimit - _bufferOffset];
                assert(_bytesWritten != 0);
                
				if (_bytesWritten == -1) {
					
					[self failWithError:
					 [self constructErrorWithCode:SCRFTPConnectionFailureErrorType
										  message:NSLocalizedString(@"Cannot continue writing file to the specified URL at the FTP server.", @"")]];
					return;
                } else {
					
					[self setStatus:SCRFTPRequestStatusWritingToStream];
					
					if ([self.delegate respondsToSelector:@selector(ftpRequest:didWriteBytes:)]) {
                        performOnMainThread(^{
                            [self.delegate ftpRequest:self didWriteBytes:_bytesWritten];
                        });
					}
					
                    _bufferOffset += _bytesWritten;
                }
            }
        } break;
        case NSStreamEventErrorOccurred: {
			[self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType
													 message:NSLocalizedString(@"Cannot open FTP connection.", @"")]];
        } break;
        case NSStreamEventEndEncountered: {
			/* Ignore */
        } break;
        default: {
            NSAssert(NO, @"Default should never happen.");
        } break;
    }
}

- (void)startCreateDirectoryRequest {
	
	if (!self.ftpURL || !self.directoryName) {
		[self failWithError:SCRFTPUnableToCreateRequestError];
		return;
	}
	
	CFURLRef createUrl = CFURLCreateCopyAppendingPathComponent(NULL, (CFURLRef)self.ftpURL, (CFStringRef)self.directoryName, true);
	if (!createUrl) {
		[self failWithError:[self constructErrorWithCode:SCRFTPInternalErrorWhileBuildingRequestType
												 message:NSLocalizedString(@"Unable to build URL to create directory.", @"")]];
		return;
	}
	
	CFWriteStreamRef createStream = CFWriteStreamCreateWithFTPURL(NULL, createUrl);
	if (!createStream) {
		[self failWithError:
		 [self constructErrorWithCode:SCRFTPUnableToCreateRequestErrorType
							  message:[NSString stringWithFormat:
									   NSLocalizedString(@"Cannot open FTP connection to %@", @""),
									   (__bridge_transfer NSURL *)createUrl]]];
//		CFRelease(createUrl);
		return;
	}
	CFRelease(createUrl);
	
	self.writeStream = (__bridge_transfer NSOutputStream *)createStream;
	[self applyCredentials];
	self.writeStream.delegate = self;
	[self.writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self.writeStream open];
	
//	CFRelease(createStream);
}

- (void)handleCreateDirectoryEvent:(NSStreamEvent)eventCode {
	
	switch (eventCode) {
        case NSStreamEventOpenCompleted: {
			[self setStatus:SCRFTPRequestStatusOpenNetworkConnection];
            /* Despite what it says in the documentation <rdar://problem/7163693>, 
             * you should wait for the NSStreamEventEndEncountered event to see 
             * if the directory was created successfully.  If you shut the stream 
             * down now, you miss any errors coming back from the server in response 
             * to the MKD command. */
        } break;
        case NSStreamEventHasBytesAvailable: {
            NSAssert(NO, @"Should never happen for the output stream."); /* Should never happen for the output stream. */
        } break;
        case NSStreamEventHasSpaceAvailable: {
            NSAssert(NO, @"Should never happen for the output stream.");
        } break;
        case NSStreamEventErrorOccurred: {
            /* -streamError does not return a useful error domain value, so we 
             * get the old school CFStreamError and check it. */
			CFStreamError err = CFWriteStreamGetError((CFWriteStreamRef)self.writeStream);
            if (err.domain == kCFStreamErrorDomainFTP) {
                [self failWithError:
				 [self constructErrorWithCode:SCRFTPConnectionFailureErrorType
									  message:[NSString stringWithFormat:NSLocalizedString(@"FTP error %d", @""), (int)err.error]]];
            } else {
				[self failWithError:
				 [self constructErrorWithCode:SCRFTPConnectionFailureErrorType
									  message:NSLocalizedString(@"Cannot open FTP connection.", @"")]];
            }
        } break;
        case NSStreamEventEndEncountered: {
			[self requestFinished];
        } break;
        default: {
            NSAssert(NO, @"Default should never happen for the output stream.");
        } break;
    }	
}

#pragma mark Complete / Failure

- (NSError *)constructErrorWithCode:(NSInteger)code message:(NSString *)message {
	
	return [NSError errorWithDomain:SCRFTPRequestErrorDomain
							   code:code
						   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:message, NSLocalizedDescriptionKey, nil]];
}

- (BOOL)isComplete {
	
	return _complete;
}

- (BOOL)isFinished {
	
	return [self isComplete];
}

- (void)requestFinished {
	
	_complete = YES;
	[self cleanUp];
	
	[self setStatus:SCRFTPRequestStatusClosedNetworkConnection];
	
    performOnMainThread(^{
        [self.delegate ftpRequestDidFinish:self];
    });
}

- (void)failWithError:(NSError *)error {
	
	_complete = YES;
	
	if (self.error != nil || [self isCancelled]) {
		return;
	}
	
	self.error = error;
	[self cleanUp];
	[self setStatus:SCRFTPRequestStatusError];
	
    performOnMainThread(^{
        [self.delegate ftpRequest:self didFailWithError:self.error];
    });
}

- (void)cleanUp {
	
	if (self.writeStream != nil) {
        [self.writeStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.writeStream.delegate = nil;
        [self.writeStream close];
        self.writeStream = nil;
    }
    if (self.readStream != nil) {
        [self.readStream close];
        self.readStream = nil;
    }
}

+ (NSOperationQueue *)sharedRequestQueue
{
	if (!sharedRequestQueue) {
		sharedRequestQueue = [[NSOperationQueue alloc] init];
		[sharedRequestQueue setMaxConcurrentOperationCount:4];
	}
	return sharedRequestQueue;
}

@end
