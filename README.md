TPC-DS BENCHMARKING POSTGRESQL
# Introduction
This repository contains the code files and the corresponding explanation of the first project conducted for the course Data Warehouses, which is part of the Big Data Management and Analytics (BDMA) - Erasmus Mundus Joint Master Degree Program. It aims to enable other users to replicate our findings and to provide a clearer explanation of the steps involved in conducting a meaningful TPC-DS benchmark for individuals interested in open-source solutions.

## Prerequisites
To proceed with this project, the user must have Docker, Ubuntu Docker Image, and PostgreSQL already downloaded and installed. If these are not yet available, they can be obtained from the following links:

- [Docker](https://www.docker.com/products/docker-desktop/)
- [Ubuntu Image](https://hub.docker.com/_/ubuntu)
- [PostgreSQL](https://www.postgresql.org/)

In addition, you should download the TPC-DS official files from the official website to follow this guide. The link is written below:

- [TPC-DS](https://www.tpc.org/tpc_documents_current_versions/current_specifications5.asp)

Finally, you will need the following files:

- `preprocess_db_setup_load_script.py`

You can download them by downloading the folder called “Necessary files”. These files were originally found in the following repository [here](https://github.com/risg99/tpc-ds-benchmark), but they have been updated to fit our file architecture and setup.

Thank you!

## File architecture
During this project, we will work with the following file architecture:

```
Project
└── TPC-DS (Official files)
    └── preprocess_db_setup_load_script.py
```

Ensure your files are correctly organized if you want to run our code.

## Step-by-step guide
We will divide this step-by-step guide into three sections. First, we will update some of the official TPC-DS files to prevent errors. Second, we will build the TPC-DS data using Ubuntu. Finally, we will create the database and load the data.

### FILE UPDATE:
Before starting the setup, we should make some small changes in the official TPC-DS files, to avoid future errors.

1. The first step we should do is to copy the content of the file `Makefile.suite`, which you can find in the folder `TPC-DS/tools`, and paste it into the file `makefile` which is also in the same folder. Before closing `makefile`, find the line containing `OS = `. Write `OS = LINUX`, it may be already written. Now search the line containing `LINUX_CC = gcc` and write `LINUX_CC = gcc-9`, instead. Save the file and close it.

2. Secondly, go to the folder `TPC-DS/tools`, create a new folder inside, and name it `tmp`.

3. Finally, search the file `netezza.tpl` in the folder `TPC-DS/query_templates`. Open it and add the following line at the end of the document: `define _END  = "";`. Save the file and close it.

Let’s begin the setup.

### TPC-DS DATA BUILD:
Let’s begin with the setup. We will divide it into seven easy steps that we will need to follow:

1. Open a terminal and run the Ubuntu docker image using the following command:
    ```sh
    docker run --name tpcds -it ubuntu
    ```
    That should convert your terminal into a Linux-based terminal. We will call this terminal Linux terminal.

2. Run in this new terminal the following two commands:
    ```sh
    apt-get update
    ```
    ```sh
    apt-get install -y gcc gcc-9 libc-dev make flex bison vim
    ```

3. Open a new terminal and run the following commands: (Note that this command should be run in the folder `Project`)
    ```sh
    docker cp ./TPC-DS tpcds:/tpc-ds
    ```

4. Go back to the Linux terminal. Now we have to open the folder called `tpc-ds` inside our container using the commands `cd` and `ls -a`. (We use `cd` to move between folders and `ls -a` to see the files and folders contained by a folder.) Once inside the folder `tools`, we run the command `make`.

5. The next step is to run the following commands:
    ```sh
    ./dsdgen -scale 1 -dir ./tmp -suffix .csv -delimiter "^" -parallel 4 -child 1 -quiet n -terminate n &
    ```
    ```sh
    ./dsdgen -scale 1 -dir ./tmp -suffix .csv -delimiter "^" -parallel 4 -child 2 -quiet n -terminate n &
    ```
    ```sh
    ./dsdgen -scale 1 -dir ./tmp -suffix .csv -delimiter "^" -parallel 4 -child 3 -quiet n -terminate n &
    ```
    ```sh
    ./dsdgen -scale 1 -dir ./tmp -suffix .csv -delimiter "^" -parallel 4 -child 4 -quiet n -terminate n &
    ```
    ```sh
    ./dsqgen -DIRECTORY ../query_templates -INPUT ../query_templates/templates.lst -VERBOSE Y -QUALIFY Y -DIALECT netezza
    ```

6. Now we go back to our other terminal and run the following command:
    ```sh
    docker cp tpcds:/tpc-ds .\TPC-DS-Built
    ```
    (Note that this command should be run in the folder `Project`)

7. Finally, we can stop the Ubuntu docker container. Run the following commands:
    ```sh
    docker stop tpcds
    ```
    ```sh
    docker rm tpcds
    ```

We are ready to jump to the last section. We have created a new folder inside your project folder. This folder should be called `TPC-DS-Built`. You can explore it, if you want, to see the differences between the old `TPC-DS` folder and this new version.

### CREATING THE DATABASE:
In this section, we will first create the database and bulk-load the data into it. We will need the file `preprocess_db_setup_load_script.py`. We should run this file inside of the folder `TPC-DS-Built`, so put it inside before continuing.

### Step 1: Set Up a Virtual Environment
Create a virtual environment and install the required dependencies.
```bash
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

### Step 2: Set Up Jupyter Notebook Kernel
Create an IPython kernel in your virtual environment to use it with Jupyter.
```bash
ipython kernel install --user --name=tpc_ds_kernel
python -m ipykernel install --user --name=tpc_ds_kernel
python -m bash_kernel.install
```

### Step 3: Replace the file tpcds_ri.sql 
Use the file `tpcds_ri.sql` from the current repository to replace the file at your `TPC-DS-Built>tools>tpcds_ri.sql` to fix potential upcoming constraint creation errors.

### Step 4: Start Jupyter Notebook
Start jupyter notebook and open the file `preprocess_db_setup_load_script.ipynb` that is stored inside of the folder `TPC-DS-Built` and then switch the kernel to `tpc_ds_kernel`. Also, in the second cell of the notebook change the port and password of PostgreSQL to the ones that your program uses. Now execute all the cells of the notebook.


This repository contains the code files and the corresponding explanation of the first project conducted for the course Data Warehouses, which is part of the Big Data Management and Analytics (BDMA) - Erasmus Mundus Joint Master Degree Program. It aims to enable other users to replicate our findings and to provide a clearer explanation of the steps involved in conducting a meaningful TPC-DS benchmark for individuals interested in open-source solutions.
