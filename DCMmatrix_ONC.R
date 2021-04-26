#### Data prep ####

# load package
library(tidyverse)
library(reshape2)
library(readxl)
library(ggcorrplot)

rootdir <- "~/Box Sync/Science/2019/rSMS_DCM/documents/DCM_PEB_final"
filetoread <- "bargraph_NC.xlsx"

df.CMPM <- read_excel(file.path(rootdir,filetoread))


# Set ROIs
ROIs <- c(
  "R_dmThal2",
  "L_dmThal2",
  "R_Hypo",
  "L_Hypo",
  "R_dlPAG",
  "R_vAI",
  "L_vAI",
  "ACC",
  "R_Amy",
  "L_Amy"
)

# Re order DCM ROIs
allROIs <- c()
for (i in 1:length(ROIs)) {
  counter = 1
  
  while (counter < 11){
    paste(ROIs)
    
    allROIs <- c(allROIs, paste(ROIs[i], ROIs[counter], sep = "-"))
    counter = counter + 1
    
  }
  
}

df.CMPM <- df.CMPM %>%
  mutate(edges = fct_relevel(edges, allROIs)) %>%
  arrange(edges)


# Read only connectivity matrix
DESELECTVARS <- c("group")


# Subset data with PP threshold
PPTHRESHOLD <- 0.99
df.CMPM <- df.CMPM %>% mutate(Ep2 = ifelse(Pp<0.99, 0, Ep))

# Create 10 x 10 matrix
convertMatrix <- function(ROIs, data){
  df <- matrix(nrow = length(ROIs), ncol = length(ROIs))
  
  for (i in 1:length(ROIs)) {
    LHS <- ((i-1)*10 + 1)
    RHS <- (i*10)
    
    target <- as.matrix(data[LHS:RHS])
    df[, i] <- target # From is x axis, To is y-axis
  }
  
  # Create row and column names
  rownames(df) <- ROIs
  colnames(df) <- ROIs
  
  return(df)
}

DCM.matrix <- convertMatrix(ROIs, df.CMPM$Ep2) %>% round(4)
DCM.Pp <- convertMatrix(ROIs, df.CMPM$Pp) %>% round(4)


# Reorder ROIs and rename
newROIs <- c(
  "R_vAI",
  "L_vAI",
  "ACC",
  "R_Amy",
  "L_Amy",
  "R_dmThal2",
  "L_dmThal2",
  "R_dlPAG",
  "R_Hypo",
  "L_Hypo"
)


newROIs2 <- gsub("_", " ", newROIs)
newROIs2 <- gsub("[0-9]", "", newROIs2)


newindex <- match(newROIs, colnames(DCM.matrix))
DCM.matrix <- DCM.matrix[newindex, newindex]
DCM.Pp <- DCM.Pp[newindex, newindex]
rownames(DCM.matrix) <- newROIs2
colnames(DCM.matrix) <- newROIs2


# Set diagonal from top going down right
# DCM.matrix <- DCM.matrix[length(ROIs):1, ]
# DCM.Pp <- DCM.Pp[length(ROIs):1, ]

# Set to 2 decimal places
DCM.matrix <- round(DCM.matrix, 2)

DCM.matrix2 <- DCM.matrix
DCM.matrix2[DCM.matrix2==0] <- NA



#### Create the plot
ggplot(data = melt(DCM.matrix, na.rm = TRUE), aes(Var1, Var2, fill = value)) +
  geom_tile(color = "gray") +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-0.175, 0.175), space = "Lab", 
                       name = "Connectivity\nValue") +
  geom_text(data = melt(DCM.matrix2),
            aes(Var1, Var2, label = value), colour = "black", size = 7) +
  theme_minimal() +
  labs(x = "To", y = "From") +
  theme(text = element_text(size=25),
        axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1),
        
        panel.background = element_rect(color = NA), 
        
        panel.grid.minor = element_blank(), 
        panel.grid = element_blank(),
        
        axis.line = element_blank(), 
        strip.background = element_blank(),
  ) +
  scale_x_discrete(expand = c(0,0)) +
  scale_y_discrete(expand = c(0,0)) +
  coord_fixed() 
