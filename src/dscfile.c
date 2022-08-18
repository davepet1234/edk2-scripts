/***********************************************************************
 * 
 * Program: dscfile.c
 * 
 * Author:  David Petrovic
 * 
 * Program to add, delete and check entries in the [Component] section
 * of a DSC file
 * 
 * Used by EDK2 Utility Scripts
 * 
 **********************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <stdbool.h>
#include <errno.h>

#define DEBUG_MODE 0

#define MAX_LINE_LEN        1000
#define MAX_SEC_NAME_LEN    100

#define TMP_FILE_EXTENSION  ".tmp"
#define BAK_FILE_EXTENSION  ".bak"

#if (DEBUG_MODE == 1)
#define TRACE(Arguments) printf Arguments
#else
#define TRACE(Arguments)
#endif

// Prototypes
static int MatchLines(char *filename, char *string);
static bool AddLine(char *srcFile, char *dstFile, char *string);
static bool DeleteLines(char *srcFile, char *dstFile, char *string);
static bool IsSectionLine(char *line, char *secName, size_t secNameLen);
static bool IsBlankLine(char *line);
static bool IsStringLine(char *line, char *string);

/***********************************************************************
 * 
 * Function:    main
 * 
 **********************************************************************/
int main(int argc, char *argv[])
{
    int retval = EXIT_FAILURE;
    
    int addflag = 0;
    int delflag = 0;
    int chkflag = 0;
    int c;
    
    char *srcFile = NULL;
    char *usrString = NULL;
    char *tmpFile = NULL;
    char *bakFile = NULL;
    
    // parse cmd line
    opterr = 1; // leave getopt to handle errors
    while ((c = getopt (argc, argv, "adc")) != -1)
        switch (c) {
        case 'a': addflag = 1; break;
        case 'd': delflag = 1; break;
        case 'c': chkflag = 1; break;
        default: return 1;
    }
    if ((argc-optind != 2) || (addflag + delflag + chkflag == 0)) {
        printf("EDK2 Utility Script Tool\n");
        printf("Add, delete and check entries in the [Component] section of a DSC file.\n");
        printf("\n");
        printf("%s <dsc file> <string> <option>\n", argv[0]);
        printf("  Options:\n");
        printf("    -a   add entry\n");
        printf("    -d   delete entry\n");
        printf("    -c   check entry\n");
        return 1;
    }
    if (addflag + delflag + chkflag != 1) {
        printf("%s: Specifiy only one option\n", argv[0]);
        return 1;
    }        
    srcFile = argv[optind];     // input filename
    usrString = argv[optind+1];  // user string
    printf("Filename: %s\n", srcFile);
    printf("String  : \"%s\"\n", usrString);
    
    if (chkflag) {
        // check file for matching lines
        int count = 0;
        count = MatchLines(srcFile, usrString);
        printf("%d matched lines\n", count);
        if (count == 0) {
            goto error_exit;
        }
    } else {
        // construct tmp & bak filenames
        tmpFile = malloc(strlen(srcFile) + strlen(TMP_FILE_EXTENSION) + 1);
        if (!tmpFile) {
            printf("Failed to allocate memory\n");
            goto error_exit;
        }
        strcpy(tmpFile, srcFile);
        strcat(tmpFile, TMP_FILE_EXTENSION);    
        
        bakFile = malloc(strlen(srcFile) + strlen(BAK_FILE_EXTENSION) + 1);
        if (!bakFile) {
            printf("Failed to allocate memory\n");
            goto error_exit;
        }
        strcpy(bakFile, srcFile);
        strcat(bakFile, BAK_FILE_EXTENSION);    
        
        // process option
        if (addflag) {
            // insert line at appropriate position in file
            if (!AddLine(srcFile, tmpFile, usrString)) {
                printf("Failed to add line\n");
                goto error_exit;
            }
        } else if (delflag) {
            // delete all matching lines
            if (!DeleteLines(srcFile, tmpFile, usrString)) {
                printf("Failed to delete lines\n");
                goto error_exit;
            }
        }
        // remove any existing bak file
        if (!access(bakFile, F_OK)) {
            if (remove(bakFile)) {
                printf("Failed to remove bak file\n");
                goto error_exit;
            }
        }
        // move src file to bak
        if (rename(srcFile, bakFile)) {
            printf("Failed to rename src file: %s\n", strerror(errno));
            goto error_exit;
        }
        // move tmp file to src
        if (rename(tmpFile, srcFile)) {
            printf("Failed to rename tmp file: %s\n", strerror(errno));
            goto error_exit;
        }
    }
    
    retval = EXIT_SUCCESS;
    
error_exit:
    if (tmpFile) free(tmpFile);
    if (bakFile) free(bakFile);
    
    TRACE(("%s\n", retval ? "FAILURE":"SUCCESS"));
    return retval;
}

/***********************************************************************
 * 
 * MatchLines() 
 * 
 **********************************************************************/
static int MatchLines(char *filename, char *string)
{
    int count = 0;
    FILE *fp = NULL;
    char *line = NULL;
    bool ComponentSection = false;
    char secName[MAX_SEC_NAME_LEN];
    int linenum;

    line = malloc(MAX_LINE_LEN);
    if (!line) {
        printf("Failed to allocate memory\n");
        goto error_exit;
    }    
    fp = fopen(filename, "r");
    if (!fp) {
        printf("Failed to open file for read: %s\n", filename);
        goto error_exit;
    }         
    linenum = 1;   
    while (fgets(line, MAX_LINE_LEN, fp)) {        
        if (IsSectionLine(line, secName, MAX_SEC_NAME_LEN)) {
            if (ComponentSection) {
                // end of component section
                break;
            }
            if (strcmp("Components", secName) == 0) {
                // start of component section
                ComponentSection = true;
                linenum++;
                continue;
            }
        }
        if (ComponentSection) {
            if (IsStringLine(line, string)) {
                printf("CHK[%4d]: %s", linenum, line);
                count++;
            }
        }
        linenum++;
    }
    
error_exit:    
    if (fp)   fclose(fp);
    if (line) free(line);

    TRACE(("MatchLines() returned %d\n", count));
    return count;
}

/***********************************************************************
 * 
 * AddLine() 
 * 
 **********************************************************************/
static bool AddLine(char *srcFile, char *dstFile, char *string)
{
    bool retval = false;
    FILE *srcFp = NULL;
    FILE *dstFp = NULL;
    char *line = NULL;
    char *usrLine = NULL;
    bool ComponentSection = false;
    char secName[MAX_SEC_NAME_LEN];
    int linenum;
    long insertPos = 0;

    line = malloc(MAX_LINE_LEN);
    if (!line) {
        printf("Failed to allocate memory\n");
        goto error_exit;
    }
    usrLine = malloc(MAX_LINE_LEN);
    if (!usrLine) {
        printf("Failed to allocate memory\n");
        goto error_exit;
    }

    // open src file
    srcFp = fopen(srcFile, "r");
    if (!srcFp) {
        printf("Failed to open file for read: %s\n", srcFile);
        goto error_exit;
    } 
    
    // read src file
    linenum = 1;   
    while (fgets(line, MAX_LINE_LEN, srcFp)) {        
        if (IsSectionLine(line, secName, MAX_SEC_NAME_LEN)) {
            if (ComponentSection) {
                // end of component section
                if (!insertPos) {
                    // no previous blank lines so insert here
                    insertPos = ftell(srcFp);
                }                    
                break;
            }
            if (strcmp("Components", secName) == 0) {
                // start of component section
                ComponentSection = true;
                linenum++;
                continue;
            }
        }
        if (ComponentSection) {
            // ADD: find postion to insert line
            if (IsBlankLine(line)) {
                if (!insertPos) {
                    // first blank line
                    insertPos = ftell(srcFp);
                }
            } else {
                insertPos = 0;
            }
        }
        linenum++;
    }
    
    // write out file
    snprintf(usrLine, MAX_LINE_LEN, "  %s\n", string);
    dstFp = fopen(dstFile, "w");
    if (!dstFp) {
        printf("Failed to open file for write: %s\n", dstFile);
        goto error_exit;
    }
    fseek(srcFp, 0, SEEK_SET);
    linenum = 1;   
    while (fgets(line, MAX_LINE_LEN, srcFp)) {
        bool writeline = true;
        if (insertPos) {
            // check if we are correct position to insert line
            if (ftell(srcFp) == insertPos) {
                printf("ADD[%4d]: %s", linenum, usrLine);
                if (fputs(usrLine, dstFp) == EOF) {
                    printf("Failed to write file: %s\n", dstFile);
                    goto error_exit;
                }
            }
        }
        if (fputs(line, dstFp) == EOF) {
            printf("Failed to write file: %s\n", dstFile);
            goto error_exit;
        }
        linenum++;
    }
    if (!insertPos) {
        // add line to end of file
        printf("ADD[%4d]: %s", linenum, usrLine);
        if (fputs(usrLine, dstFp) == EOF) {
            printf("Failed to write file: %s\n", dstFile);
            goto error_exit;
        }
    }
    
    retval = true;

error_exit:
    if (srcFp)   fclose(srcFp);
    if (dstFp) {
        fflush(dstFp);
        fclose(dstFp);
    }
    if (line)    free(line);
    if (usrLine) free(usrLine);
    
    TRACE(("AddLine() returned %d\n", retval));
    return retval;
}

/***********************************************************************
 * 
 * DeleteLines() 
 * 
 **********************************************************************/
static bool DeleteLines(char *srcFile, char *dstFile, char *string)
{
    bool retval = false;
    FILE *srcFp = NULL;
    FILE *dstFp = NULL;
    char *line = NULL;
    bool ComponentSection = false;
    char secName[MAX_SEC_NAME_LEN];
    int linenum;

    line = malloc(MAX_LINE_LEN);
    if (!line) {
        printf("Failed to allocate memory\n");
        goto error_exit;
    }
    // open src file
    srcFp = fopen(srcFile, "r");
    if (!srcFp) {
        printf("Failed to open file for read: %s\n", srcFile);
        goto error_exit;
    } 
    // write out file
    dstFp = fopen(dstFile, "w");
    if (!dstFp) {
        printf("Failed to open file for write: %s\n", dstFile);
        goto error_exit;
    }
    linenum = 1;   
    while (fgets(line, MAX_LINE_LEN, srcFp)) {
        if (IsSectionLine(line, secName, MAX_SEC_NAME_LEN)) {
            if (ComponentSection) {
                // end of component section
                ComponentSection = false;
            }
            if (strcmp("Components", secName) == 0) {
                // start of component section
                ComponentSection = true;
                linenum++;
                continue;
            }
        }
        if (ComponentSection && IsStringLine(line, string)) {
            // remove line
            printf("DEL[%4d]: %s", linenum, line);
        } else {
            // keep line
            if (fputs(line, dstFp) == EOF) {
                printf("Failed to write file: %s\n", dstFile);
                goto error_exit;
            }
        }
        linenum++;
    }
    
    retval = true;
    
error_exit:
    if (srcFp) fclose(srcFp);
    if (dstFp) {
        fflush(dstFp);
        fclose(dstFp);
    }
    if (line)  free(line);

    TRACE(("DeleteLines() returned %d\n", retval));
    return retval;
}

/***********************************************************************
 * 
 * IsSectionLine()
 * 
 **********************************************************************/
static bool IsSectionLine(char *line, char *secName, size_t secNameLen)
{
    int i = 0;
    int start, end, len;
    
    while (isspace(line[i])) {
        i++;
    }
    if (line[i++] != '[') {
        return false;
    }
    start = i;
    while (isalnum(line[i])) {
        i++;
    }
    if (line[i] != ']') {
        return false;
    }
    end = i-1;
    len = end-start+1;
    if (len > secNameLen-1) {
        len = secNameLen-1;
    }
    if (secName) {
        strncpy(secName, &line[start], len);
        secName[len] = '\0';
    }
    return true;
}

/***********************************************************************
 * 
 * IsBlankLine()
 * 
 **********************************************************************/
static bool IsBlankLine(char *line)
{
    int i = 0;
    
    while (isspace(line[i])) {
        i++;
    }
    return line[i] == 0 ? true:false;
}

/***********************************************************************
 * 
 * IsStringLine()
 * 
 **********************************************************************/
static bool IsStringLine(char *line, char *string)
{
    int i = 0;
    int len;
    
    while (isspace(line[i])) {
        i++;
    }
    len = strlen(string);
    return strncmp(&line[i], string, len) == 0 ? true:false;
}
