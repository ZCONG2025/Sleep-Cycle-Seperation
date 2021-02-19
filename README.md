# Sleep-Cycle-Seperation User Guide
This is an APP for visualizing hypnogram and marking the ranges of each sleep cycle. Since it is still the first version, many functions are still under development. In order to avoid any possible bugs, the following procedure is recommended:

1. Data Preperation. 

    The APP runs based on some EEGLAB functions, so it is highly recommended that your EEGLAB has been upgraded to a recent version in case some changes of the functions had been made.
    
    The APP now only recognizes .fdt and .set files, labelled with hypnogram as **Events**. To learn how to label events in EEG file, please refer to ***eeg_addnewevents()*** function in EEGLAB for more information. For events, set following numbers as a representative to certain stages: '0': Awake; '1': N1; '2': N2; '3': N3; '4': REM.

2. Processing.

    Open the APP by using MATLAB console or MATLAB APP Designer;
    
    Click 'Create New Set' on the left pannel;
    
    In the pop-up window, browse the EEG files in local storage (multi-selecting enabled). Note: EEGLAB only recognize .fdt files with .set files in the same folder.
    
    Set your own name of the dataset and press OK. The APP will automatically load in the first EEG file and plot the hypnogram in the main pannel.
    
    Click on the window to define ending points of each cycle.
    
    
    The APP is running based on the following criteria: the start point of one sleep cycle is predefined. The start point of the first cycle is the start point of the hypnogram. The ending point of one cycle is always the last point of one stage (typically REM). No matter which point you click in this stage, the ending point will always be marked as the last point. Then the APP moves to the next cycle by setting the start point to the next point after this stage.
    
    Press 'Delete' if you want to delete the ending point you've chosen. Press 'Clear' to clear all the cycle information of this subject. 
    
    When you finish one subject, press 'Next'. If AutoSave is on (default), the APP will generate a .mat file containing all the information of the sleep cycles, useful for further coding. Always remember to press 'Next' when you return to a previous subject and make modifications.
   
3. Notes.

    'Load Existing Set' currently doesn't work, but will be made available soon.
    
    'Subjects' and 'Datasets' pannels doesn't work, which means multiple groups of data should not be loaded into the APP.
