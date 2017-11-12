//
//  ViewController.h
//  SpeechAppC2
//
//  Created by Sebastian Strus on 2017-11-11.
//  Copyright © 2017 Sebastian Strus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Speech/Speech.h>

@interface ViewController : UIViewController <SFSpeechRecognizerDelegate> {
    SFSpeechRecognizer *speechRecognizer;
    SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
    SFSpeechRecognitionTask *recognitionTask;
    AVAudioEngine *audioEngine;
}

@end

