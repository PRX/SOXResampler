    SOXResamplerConfiguration *config = SOXResamplerConfiguration.publicRadioConfiguration;
    SOXResampler *resampler = [SOXResampler resamplerWithConfiguration:config delegate:self operationQueue:nil];

    NSURL *fileURL = [NSURL fileURLWithPath:@"~/Desktop/master-2014_02_19-b.wav"];
    SOXResamplerTask *task = [resampler taskWithURL:fileURL];
    [task resume];
