clc
clear ALL
close ALL
%array 2d for low, high and medium for every letter, 27 with space
Freq = [ [400, 800, 1600]; [400, 800, 2400]; [400, 800, 4000]; [400, 1200, 1600]; [400, 1200, 2400]; [400, 1200, 4000];
         [400, 2000, 1600]; [400, 2000, 2400]; [400, 2000, 4000]; [600, 800, 1600]; [600, 800, 2400]; [600, 800, 4000];
         [600, 1200, 1600]; [600, 1200, 2400]; [600, 1200, 4000]; [600, 2000, 1600]; [600, 2000, 2400]; [600, 2000, 4000];
         [1000, 800, 1600]; [1000, 800, 2400]; [1000, 800, 4000]; [1000, 1200, 1600]; [1000, 1200, 2400];
         [1000, 1200, 4000]; [1000, 2000, 1600]; [1000, 2000, 2400]; [1000, 2000, 4000] ];
%menu
while true
    disp("Please choose the process you would like to perform:")
    disp("1) Encode a text")
    disp("2) Decode to a text")
    disp("3) Exit")
    ch = input("Please enter your choice: ", "s");
    if(ch == '1')
        Fs = 8000;%the sample frequency
        Signal = String_Encoder(Freq);%encodeing function
        %plot(Signal)
        %sound(Signal, Fs)
        Signal_normalized = Signal/(max(abs(Signal))); %normalize to change from -1 to 1 (range of numbers) for audio write function
        audiowrite("output.wav", Signal_normalized, Fs);
        disp("The name of the output file is: ")
        disp("output.wav")
    elseif (ch == '2')
        String = String_Decoder(Freq);%decoding function
        disp("The Message is:")
        disp(String)
    elseif (ch == '3')    
        disp("Goodbye :)")
        break    
    else 
        disp("Please enter a valid choice")
    end
        disp("/*************************/")
end
function Signal = String_Encoder(Freq)%array
    Fs = 8000; 
    %320 sample
    n = 0:319;
    data = "";
    while true
        data = input("Please enter a string: ", 's');
        checkdata = data(~isspace(data));
        TF = isletter(checkdata);
        if sum(TF) == length(checkdata)
            break
        end
        disp("Error in input, it must be only include characters")
    end
    Ascii = double(data); %converting to ascii 
    Signal = []; %the array we add cos for each char to converte it to the wav file
    L = length(Ascii); %how many char in each string 
    for i = 1:L 
        x = Ascii(i);
        index = 0;
        FSOC = 0;%this variable is to declare if its small or capital 
        if (x >= 65) && (x <= 90)%capital
            index = x - 64;
            FSOC = 200;
        elseif (x >= 97) && (x <= 122)  %small
            index = x - 96;
            FSOC = 100;
        elseif (x == 32)%space
            index = 27;
            FSOC = 100;
        else
        disp("Error in input, it must be only include characters")
        end
        FL = Freq(index, 1); %to get the value from the array
        FM = Freq(index, 2);
        FH = Freq(index, 3);
        temp = cos((2.*pi.*FL.*n) / Fs) + cos((2.*pi.*FM.*n) / Fs) + cos((2.*pi.*FH.*n) / Fs) + cos((2.*pi.*FSOC.*n) / Fs);%signal of the character
        Signal = cat(2, Signal, temp); 
    end    
end
function String = String_Decoder(Freq)
    Fs = 0;
    while true
        filename = input("Please enter the file's name: ", 's');
        Format = ".wav";
        num = length(filename);
        if num < 4
             filename = filename + Format;
        else
            checkFormat = filename(num - 3: num);
            if(strcmp(checkFormat, Format) == 0)
                filename = filename + Format;
            end
        end
        try
            [data, Fs] = audioread(filename);
        catch
            disp("Please enter a valid file name")
        end 
        if(Fs ~= 0)
            break
        end
    end
    LL = length(data);
    number = LL/320; %to know how many numbers cuz each number has 320 sample
    %to devide the data into multiples of 320s
    start = 1;
    finish = 320;
    asciiofstring = zeros(1, number); %to add the ascii of every char
    while true
        disp("As for part two, how would you like to encode the audio")
        disp("1) using fourier approach")
        disp("2) using filters approach")
        choice = input("Please enter your choice: ", "s");
        if(choice == '1')
            for i = 1:number %loop from 1 to number of chars
                dataofchar = data(start:finish);
                Y = fft(dataofchar, 256); %forier transform using 256 sample for accuracy, fft gives shift and amp.
                Y = abs(Y(1:132)); %gives amplitude, 132 for mirroring (half of the value)
                [x, z] = findpeaks(Y); %to get peaks in the plot
                %to find highest 4 peaks to find x
                xofpeak = zeros(1, 4);
                for j = 1:4
                     xmax = max(x);
                     indexofpeak = find(x==xmax);
                     xofpeak(j) = z(indexofpeak);
                     x(indexofpeak) = 0;
                end   
                %to find frequency value
                f = zeros(1,4);
                for j = 1:4
                    f(j) = xofpeak(j);
                    f(j) = f(j)/132; 
                    f(j) = f(j)*4125; 
                end 
                start = start +  320; %to get to next char
                finish = finish + 320;
                f = Approximation(f); 
                Ascii = getChar(f, Freq); %to get ascii code of char
                asciiofstring(i) = Ascii;
            end
            break
        elseif(choice == '2')
            N = 320;       %// Order
            FreqFilter = [100, 200, 400, 600, 800, 1000, 1200, 1600, 2000, 2400, 4000];
            b1 = fir1(N, [90 110]/(Fs/2), 'bandpass');%setting the FIR filter
            b2  = fir1(N, [190 210]/(Fs/2), 'bandpass');
            b3  = fir1(N, [390 410]/(Fs/2), 'bandpass');
            b4  = fir1(N, [590 610]/(Fs/2), 'bandpass');
            b5  = fir1(N, [790 810]/(Fs/2), 'bandpass');
            b6  = fir1(N, [990 1010]/(Fs/2), 'bandpass');
            b7  = fir1(N, [1190 1210]/(Fs/2), 'bandpass');
            b8  = fir1(N, [1590 1610]/(Fs/2), 'bandpass');
            b9  = fir1(N, [1990 2010]/(Fs/2), 'bandpass');
            b10  = fir1(N, [2390 2410]/(Fs/2), 'bandpass');
            b11  = fir1(N, [3500 3999]/(Fs/2), 'bandpass');
            Filters = [b1; b2; b3; b4; b5; b6; b7; b8; b9; b10; b11];
            for i = 1:number
                dataofchar = data(start:finish);
                power = zeros(1, 11); %initializing power for every filter
                for j = 1:11
                    yfilter = filter(Filters(j, (1:321)), 1, dataofchar);%filtering
                    x = sum(yfilter);%summing the value of the filter
                    power(j) = x.^2;%power the summed value
                end
                F = zeros(1, 4);
                for j = 1:4%to get the endex of the power
                    powermax = max(power);
                    indexofmax = find(power == powermax);
                    F(j) = FreqFilter(indexofmax);    
                    power(indexofmax) = 0;
                end   
                start = start +  320;
                finish = finish + 320;
                Ascii = getChar(F, Freq);
                asciiofstring(i) = Ascii;
            end
            break
        else
            disp("/*************************/")
            disp("Please enter a valid choice")
            disp("/*************************/")
        end
    end
    disp("/*************************/")
    String = char(asciiofstring);
end

function ApproximateInput = Approximation(input)%to approximate every signal that we get from the fourier part in order to get the characters back
    ApproximateInput=zeros(1,4);
    for i = 1:4
        if (input(i) >= 100) && (input(i) < 200)
            ApproximateInput(i) = 100;
        elseif (input(i) >= 200) && (input(i) < 300)
            ApproximateInput(i) = 200;
        elseif (input(i) >= 400) && (input(i) < 500)
            ApproximateInput(i) = 400;
        elseif (input(i) >= 600) && (input(i) < 700)
            ApproximateInput(i) = 600;   
        elseif (input(i) >= 800) && (input(i) < 900)
            ApproximateInput(i) = 800;            
        elseif (input(i) >= 1000) && (input(i) < 1100)
            ApproximateInput(i) = 1000;
        elseif (input(i) >= 1200) && (input(i) < 1300)
            ApproximateInput(i) = 1200;  
        elseif (input(i) >= 1600) && (input(i) < 1700)
            ApproximateInput(i) = 1600;
        elseif (input(i) >= 2000) && (input(i) < 2100)
            ApproximateInput(i) = 2000;  
        elseif (input(i) >= 2400) && (input(i) < 2500)
            ApproximateInput(i) = 2400;  
        elseif (input(i) >= 3400) && (input(i) < 4100)
            ApproximateInput(i) = 4000;   
        else 
            ApproximateInput(i) = 50;
        end    
    end
end

function Asciichar = getChar(input, Freqs)
    index = 0;
    input = sort(input); %sorting ascending 
    %intersect is to get the number of matching values in array
    val = intersect(input, Freqs(27, (1:3))); %compare space with char 
    SpaceMatch =length(val);
    if (SpaceMatch == 3)
        index=27;
    else
        for j = 1:26
            tempval = intersect(input,Freqs(j, (1:3))); %comparing chars to find which char we have
            found = length(tempval);
            if (found == 3)
                index = j;                        
            end    
        end
    end 
    if(index == 27)%space
        Asciichar = 32;
    elseif(input(1) == 100)%small
        Asciichar = index + 96;
    elseif(input(1) == 200)%capital
        Asciichar = index + 64;  
    end 
end
