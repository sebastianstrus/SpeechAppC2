//
//  ViewController.m
//  SpeechAppC2
//
//  Created by Sebastian Strus on 2017-11-11.
//  Copyright © 2017 Sebastian Strus. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) NSString *detectedText;
@property(nonatomic, assign) int counter;

@end

@implementation ViewController

NSTimer *t;
NSTimer *checkTimer;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _counter = 1;
    // Initialize the Speech Recognizer with the locale, couldn't find a list of locales
    // but I assume it's standard UTF-8 https://wiki.archlinux.org/index.php/locale
    speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    
    // Set speech recognizer delegate
    speechRecognizer.delegate = self;
    
    // Request the authorization to make sure the user is asked for permission so you can
    // get an authorized response, also remember to change the .plist file, check the repo's
    // readme file or this project's info.plist
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                NSLog(@"Authorized");
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
                NSLog(@"Denied");
                break;
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                NSLog(@"Not Determined");
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                NSLog(@"Restricted");
                break;
            default:
                break;
        }
    }];
    
    
    t = [NSTimer scheduledTimerWithTimeInterval: 10.0
                                                  target: self
                                                selector:@selector(onTick)
                                                userInfo: nil repeats:YES];
    
    checkTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0
                                                           target: self
                                                         selector:@selector(checkText)
                                                         userInfo: nil repeats:YES];
}

- (void) onTick {
    NSLog(@"Tick! Restart listening! %d", _counter);
    _counter++;
    [self restartListening];
}


- (void) checkText {
    NSLog(@"Check...");
    if ([[_detectedText lowercaseString] containsString:@"help"]) { //crash on iOS 7 device
        [t invalidate];
        [checkTimer invalidate];
        [audioEngine stop];
        [recognitionRequest endAudio];
        NSLog(@"Activate!!!");
    }
}


- (void)startListening {
    
    // Initialize the AVAudioEngine
    audioEngine = [[AVAudioEngine alloc] init];
    
    // Make sure there's not a recognition task already running
    if (recognitionTask) {
        [recognitionTask cancel];
        recognitionTask = nil;
    }
    
    // Starts an AVAudio Session
    NSError *error;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    
    // Starts a recognition process, in the block it logs the input or stops the audio
    // process if there's an error.
    recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode *inputNode = audioEngine.inputNode;
    recognitionRequest.shouldReportPartialResults = YES;
    recognitionTask = [speechRecognizer recognitionTaskWithRequest:recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        BOOL isFinal = NO;
        if (result) {
            // Whatever you say in the microphone after pressing the button should be being logged
            // in the console.
            NSLog(@"RESULT:%@",result.bestTranscription.formattedString);
            _detectedText = result.bestTranscription.formattedString;
            isFinal = !result.isFinal;
        }
        if (error) {
            [audioEngine stop];
            [inputNode removeTapOnBus:0];
            recognitionRequest = nil;
            recognitionTask = nil;
        }
    }];
    
    // Sets the recording format
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [recognitionRequest appendAudioPCMBuffer:buffer];
    }];
    
    // Starts the audio engine, i.e. it starts listening.
    [audioEngine prepare];
    [audioEngine startAndReturnError:&error];
    NSLog(@"Say Something, I'm listening");
}

- (IBAction)microPhoneTapped:(id)sender {
    [self restartListening];
}
- (void)restartListening {
    if (audioEngine.isRunning) {
        [audioEngine stop];
        [recognitionRequest endAudio];
        
        [self performSelector:@selector(startListening)
                   withObject:(self)
                   afterDelay:(0.5)];
        
    } else {
        [self startListening];
    }
}


#pragma mark - SFSpeechRecognizerDelegate Delegate Methods

- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
    NSLog(@"Availability:%d",available);
}


@end
