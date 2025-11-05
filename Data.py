# This Python script translates the functionality of the provided R code, primarily using the **pandas** library for data manipulation, which is the standard equivalent to R's **dplyr** and data frame operations.
# 
# The script addresses:
# 
# 1.  Setting up necessary variables and imports.
# 2.  Loading and cleaning the names of multiple CSV files into a dictionary of DataFrames.
# 3.  Filtering for patients and encounters related to **diabetes**.
# 4.  Joining the diabetes-related patient and encounter data.
# 5.  Filtering medications for **Metformin** (based on `rxnorm_lookup`) and joining this to the patient/encounter data.
# 6.  Calculating and summarizing **age distribution** (average, min, max) for living and deceased patients.

import pandas as pd
import numpy as np
import os
import re
import pprint
from pathlib import Path
from datetime import date

# init ----
debug = 0
seed = 22
datasource = Path("./output/csv/")
rxnorm_file = Path("./output/Metformin_RxNav_6809_table.csv")
today = pd.to_datetime(date.today())

# Helper function (not used in R, but good for setup)
def check_unique(df):
    """Checks if the number of rows equals the number of unique rows."""
    return len(df) == len(df.drop_duplicates())

# Load rxnorm lookup data
try:
    # skip=2 lines, similar to R's import
    rxnorm_lookup = pd.read_csv(rxnorm_file, skiprows=2)
    
    # Filter termType (BN, IN, MIN, PIN, SBD, SBDC, SBDF, SBDFP, SBDG, SCD, SCDC, SCDF, SCDG)
    target_terms = ["BN","IN","MIN","PIN","SBD","SBDC","SBDF","SBDFP","SBDG","SCD","SCDC","SCDF","SCDG"]
    rxnorm_lookup = rxnorm_lookup[rxnorm_lookup['termType'].isin(target_terms)]
except FileNotFoundError:
    print(f"Warning: RxNorm file not found at {rxnorm_file}. Creating dummy lookup.")
    # Create a dummy DataFrame for rxcui if file is missing
    rxnorm_lookup = pd.DataFrame({'rxcui': [81093, 7000, 6809], 'termType': ['SCD', 'IN', 'IN']})


# Load all dataframes from the source directory
data0 = {}
if datasource.is_dir():
    for f in datasource.glob("*.csv"):
        # Rename objects: remove prefix './output/csv/' and suffix '.csv'
        name = re.sub(r"^" + re.escape(str(datasource)) + r"/?|\.csv$", "", str(f))
        try:
            data0[name] = pd.read_csv(f)
        except Exception as e:
            print(f"Error loading {f.name}: {e}")
else:
    print(f"Warning: Data source directory not found at {datasource}. Creating dummy data.")
    # Create dummy dataframes if the directory is missing for demonstration/testing
    data0 = {
        'patients': pd.DataFrame({'Id': ['P1', 'P2', 'P3'], 
                                  'BIRTHDATE': ['1960-01-01', '1980-05-15', '2000-10-10'], 
                                  'DEATHDATE': [np.nan, '2024-01-01', np.nan]}),
        'encounters': pd.DataFrame({'Id': ['E1', 'E2', 'E3', 'E4'], 'PATIENT': ['P1', 'P1', 'P2', 'P3']}),
        'conditions': pd.DataFrame({'PATIENT': ['P1', 'P2', 'P3'], 'ENCOUNTER': ['E1', 'E3', 'E4'], 
                                    'DESCRIPTION': ['Type 2 Diabetes', 'Hypertension', 'Pre-diabetic condition']}),
        'medications': pd.DataFrame({'ENCOUNTER': ['E1', 'E2', 'E4'], 'CODE': [6809, 1234, 7000]}) # 6809 is a dummy metformin rxcui
    }


# How to find and extract data from a data frame ----

# Find matches for diabetes from 'conditions' and extract patient/encounter IDs
# Use regex with word boundary (\b) and case-insensitive (case=False)
if 'conditions' in data0:
    diabetes_conditions = data0['conditions'][
        data0['conditions']['DESCRIPTION'].str.contains(r'\bdiab', case=False, na=False, regex=True)
    ]

    criteria = {
        'patient_diabetes': set(diabetes_conditions['PATIENT'].unique()),
        'encounter_diabetes': set(diabetes_conditions['ENCOUNTER'].unique())
    }

    # Filter patients and encounters
    data_diab_patients = data0['patients'][data0['patients']['Id'].isin(criteria['patient_diabetes'])]
    data_diab_encounters = data0['encounters'][data0['encounters']['Id'].isin(criteria['encounter_diabetes'])]

    # Validate if all diabetes patients have an associated diabetes encounter
    patients_missing_encounter = criteria['patient_diabetes'].difference(data_diab_encounters['PATIENT'])
    encounters_missing_patient = set(data_diab_encounters['PATIENT']).difference(criteria['patient_diabetes'])
    
    # setdiff(criteria$patient_diabetes,data_diab_encounters$PATIENT)
    print(f"Patients in conditions but not in filtered encounters: {patients_missing_encounter}") 
    # setdiff(data_diab_encounters$PATIENT,criteria$patient_diabetes)
    print(f"Patients in filtered encounters but not in conditions: {encounters_missing_patient}")

    # Join patients and encounters (left_join: data_diab_patients, data_diab_encounters, by=c("Id"="PATIENT"))
    data_diab_patient_encounters = pd.merge(
        data_diab_patients, 
        data_diab_encounters, 
        left_on='Id', 
        right_on='PATIENT', 
        how='left', 
        suffixes=('', '.y')
    ).rename(columns={'Id.y': 'ENCOUNTER'}) # R's mutate(ENCOUNTER=Id.y)

    # Validation check (R's if/stop)
    if len(data_diab_patient_encounters) != len(data_diab_encounters):
         print("WARNING: Join rows do not match the diabetes encounter dataset. This may be due to encounters without matching patients in the *initial* patient file.")
    else:
        print("All clear (join row count matched).")

    # Metformin filtering and joining
    # Filter medications by CODE being in rxnorm_lookup$rxcui
    med_met = data0['medications'][data0['medications']['CODE'].isin(rxnorm_lookup['rxcui'])].copy(deep=True)
    med_met["TOTALCOST_Rounded"]= med_met ["TOTALCOST"].round() #round total cost of medication
    
    # left_join(data_diab_patient_encounters, med_met, by=c("ENCOUNTER"="ENCOUNTER"))
    data_diab_encountersmet = pd.merge(
        data_diab_patient_encounters, 
        med_met, 
        on='ENCOUNTER', 
        how='left', 
        suffixes=('_pat_enc', '_med')
    )
    print("\n--- Data joined with Metformin medications (Head) ---")
    print(data_diab_encountersmet.head())

# Age distribution (average, min, max) ----
if 'patients' in data0:
    patients_df = data0['patients'].copy()

    # Convert dates
    patients_df['DEATHDATE'] = pd.to_datetime(patients_df['DEATHDATE'], errors="coerce")
    patients_df['BIRTHDATE'] = pd.to_datetime(patients_df['BIRTHDATE'], errors="coerce")

    # alive=is.na(DEATHDATE)
    patients_df['alive'] = patients_df['DEATHDATE'].isna()
    #Today's date
    today=pd.Timestamp.today()
    #Create endate= earlier of today or deat date
    #enddate=(pmin(Sys.Date(),DEATHDATE,na.rm = TRUE))
    # numpy.minimum handles element-wise minimum, using pd.NaT for missing dates
    patients_df['enddate'] = patients_df['DEATHDATE'].where(patients_df["DEATHDATE"]<today,
    today)
    patients_df['enddate'] = patients_df['enddate'].fillna(today) # If both DEATHDATE and today are valid, use the smaller. If DEATHDATE is NA, use today (as na.rm=TRUE does).

    # age=as.numeric(enddate-BIRTHDATE)/365.25
    patients_df['age'] = (patients_df['enddate'] - patients_df['BIRTHDATE']).dt.days / 365.25

    # Group by alive and summarize
    age_summary = patients_df.groupby('alive')["age"].agg(
        avg_age="mean",
        min_age="min",
        max_age="max",
        count="count"
    ).reset_index()

    # Rename alive status for readability
    age_summary['alive'] = age_summary['alive'].map({True: 'Alive', False: 'Deceased'})
    
    print("\n--- Age Distribution Summary ---")
    print(age_summary)
#use repl_python() in the console to interact with python interface
#.keys() use to see all the objects in a list

# They are several ways to round a number. below you will find two different codes to round.
  #Option 1: data0["medications"]["TOTALCOST"].round()
  #Option 2: round(data0["medications"]["TOTALCOST"])
  
# Converting a column to a Pyton list (AKA vector in R)
med_met["TOTALCOST"].tolist() #gives you raw numbers 
TOTALCOST_list=med_met["TOTALCOST"].tolist() 

#Lists
#There are several ways to transform a value in list. Below you will find 3 commands to round a number in this list. 
result=[]
for xx in TOTALCOST_list:
  #result=result+[round(xx)]
  #result+=[round(xx)]
  result.append(round(xx))

# List Comprehension
result2=[round(xx) for xx in TOTALCOST_list] 

result3=[round(xx) for xx in TOTALCOST_list if xx >10] #if you want to "filter" to match a particular criteria

result4=[round(xx)  if xx >10 else -1 for xx in TOTALCOST_list] #if doing "if" "else" you have to have "if" first

# Dictionaries
#There are several ways to create a dictionary
dresult={}
for xx in data0.keys():
  #dresult[xx]=data0[xx].keys().tolist()
  dresult.update({xx:data0[xx].keys().tolist()})

pprint.pprint(dresult) #to see the dictionary in a more formated way


{"patients":['Id', 'BIRTHDATE', 'DEATHDATE', 'SSN', 'DRIVERS'],"observations":['ENCOUNTER', 'CATEGORY', 'CODE', 'DESCRIPTION']}


#Dictionary Comprehension

dresult2={xx:data0[xx].keys().tolist() for xx in data0.keys()}
pprint.pprint(dresult2)

#Creating Dictionary with Zip
#1.create list of keys to preserve order
tablenames=data0.keys()

#2.create a list with table names using list comprehension
columnnames=[data0[xx].keys().tolist() for xx in tablenames]

#3Combine the list of keys with the list 
dresult3=dict(zip(tablenames, columnnames))
pprint.pprint(dresult3)


