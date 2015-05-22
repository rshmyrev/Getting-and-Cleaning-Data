# load library
library(data.table)
library(dplyr)
library(LaF) # fast access to large fixed width files

# Download and unzip data
if (!file.exists("data")) {
    dir.create("data")
}
destfile = "./data/UCI HAR Dataset.zip"
fileUrl <- "https://d396qusza40orc.cloudfront.net/getdata/projectfiles/UCI%20HAR%20Dataset.zip"
download.file(fileUrl, destfile = destfile, method = "curl")
unzip(destfile, exdir = 'data')
file.remove(destfile)

# Variable names and activity names
features <- read.table("./data/UCI HAR Dataset/features.txt",
                       sep = " ", stringsAsFactors = FALSE,
                       col.names = c("column", "name"))
activity_labels <- read.table("./data/UCI HAR Dataset/activity_labels.txt",
                       sep = " ", stringsAsFactors = FALSE,
                       col.names = c("level", "label"))

# Load the training and the test sets
subject_test <- read.table("./data/UCI HAR Dataset/test/subject_test.txt")
subject_train <- read.table("./data/UCI HAR Dataset/train/subject_train.txt")

y_test <- read.table("./data/UCI HAR Dataset/test/y_test.txt")
y_train <- read.table("./data/UCI HAR Dataset/train/y_train.txt")

X_test <- laf_open_fwf("./data/UCI HAR Dataset/test/X_test.txt",
                       column_types = rep("numeric", 561),
                       column_widths = rep(16, 561))[,]
X_train <- laf_open_fwf("./data/UCI HAR Dataset/train/X_train.txt",
                        column_types = rep("numeric", 561),
                        column_widths = rep(16, 561))[,]

# Merge the training and the test sets in one data table
subject <- rbind(subject_test, subject_train)
y       <- rbind(y_test, y_train)
X       <- rbind(X_test, X_train)
names <- c("subject", "activity", features$name)
names(subject) <- "subject"
names(y) <- "activity"
names(X) <- features$name
DT <- data.table(subject, y, X)

# Extract only the measurements on the mean and standard deviation for each measurement
DT <- select(DT, subject, activity, contains("mean()"), contains("std()"))

# Set activity names
DT$activity <- factor(DT$activity,
                      levels = activity_labels$level,
                      labels = activity_labels$label)

# Create data set with the average of each variable for each activity and each subject
DT_mean <- summarise_each(group_by(DT, subject, activity), funs(mean))

# Sort by subject and activity
DT_mean <- arrange(DT_mean, subject, activity)

# Write data table
write.table(DT_mean, file = "tidy data.txt", row.name=FALSE)
