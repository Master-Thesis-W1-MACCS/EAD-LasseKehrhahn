# # MAIN FUNCTION FOR GENERATING A PRODUCT PROGRAM
gen_EAD <- function(EAD,TQ) {

  #  % 23.4. - Generates the customers in the market Customer generation function
  #  % 24.7. - Make customers' attributes more precise, in particular CN and FRN
  #  % 01.10 - Code simplification 
  #  % 04.2  - Cost calculation implemented
  #  % 05.02 - Simulation has been implemented 
  #  % 25.02 - Update Product architecture generation
  #  % 19.03 - Update Demand function
  #  % 19.03 - Update Customer diversity 
  #  % 19.03 - Market structure
  
  
  
  
  #### PREDETERMINING ====
  DENS_CCN =  EAD$DENS_CCN
  DENS_CNFR = EAD$DENS_CNFR
  DENS_FRCM = EAD$DENS_FRCM
  DENS_CMPV = EAD$DENS_CMPV
  DENS_PVRC = EAD$DENS_PVRC
  NUMB_C = EAD$NUMB_C #Customers
  NUMB_CN = EAD$NUMB_CN #Customer' needs 
  NUMB_FR = EAD$NUMB_FR #Functional Requirements
  NUMB_CM = EAD$NUMB_CM #Components
  NUMB_PV = EAD$NUMB_PV #Processes
  NUMB_RC = EAD$NUMB_RC #Resources
  Q_VAR = EAD$Q_VAR
  
  #### DEMAND GENERATION ####
  
  C_DEMAND <- .gen_Demand(NUMB_C, TQ, Q_VAR)
  EAD$C_DEMAND <- C_DEMAND
  
  #### CUSTOMER DIVERSITY ####
  
  A_CCN =  .create_designmatrix(NUMB_C,NUMB_CN,DENS_CCN,"C","CN") #Customer - Customer Needs Matrix
  
  CN = C_DEMAND %*% (A_CCN)  #computing CN * q from the customers
  EAD$CN = CN
  
  
  #### MARKET STRUCTURE  ####
  
  A_CNFR = .create_designmatrix(NUMB_CN,NUMB_FR,DENS_CNFR,"CN","FR") #Customer Needs - Functional Requirements Matrix
  
  FR = as.vector(CN) %*% (A_CNFR)   # computing FR * q
  EAD$FR = FR
  
  
  #### PRODUCT ARCHITECTURE ####
  
  A_FRCM = .create_designmatrix(NUMB_FR,NUMB_CM,DENS_FRCM,"FR","CM") #Functional Requirements - Components Matrix
  
  #Number of functional requirements must be equal to the number of components. (symmetrical matrix needed)
  #  if(EAD$TYPE_FRCM != "C"){
  #  if(sum(diag(A_FRCM))<NUMB_FR)  {
  #   diag(A_FRCM) <- 1
  #   A_FRCM[!lower.tri(A_FRCM,diag=TRUE)] <- 0
  # }
  #  }
  EAD$DENS_FRCM_measured = count_nonzeros(A_FRCM) #set DENS_FRCM is not strictly the implemented. 
  
  CM = as.vector(FR) %*% (A_FRCM) # computing CM * q
  EAD$CM = CM
  
  #### PRODUCTION TECHNOLOGY ####
  
  
  EAD = gen_ProductionEnvironment(EAD,NUMB_CM,NUMB_PV,DENS_CMPV)
  A_CMPV = EAD$A_CMPV
  A_PVRC = .create_designmatrix(NUMB_PV,NUMB_RC,DENS_PVRC,"PV","RC") #Processed - Resources Matrix
  
  PV = as.vector(CM) %*% (A_CMPV) # computing CM * q
  EAD$PV = PV
  
  #### EAD COMPUTING ####
  
  RC = as.vector(PV) %*% (A_PVRC) # computing CM * q
  
  EAD$RC = RC
  
  RCC = matrix(.gen_RCC(RCC_VAR,1*10^6,RC))
  #RCU = (RCC/RC)
  
  
  #### COST COMPUTING ####
  
  A_PVRCp <- sweep((A_PVRC),2,colSums(A_PVRC),"/") #Absolute matrix to relative matrix
  A_CMPVp <- sweep((A_CMPV),2,colSums(A_CMPV),"/") #Absolute matrix to relative matrix  
  A_FRCMp <- sweep((A_FRCM),2,colSums(A_FRCM),"/") #Absolute matrix to relative matrix
  A_CNFRp <- sweep((A_CNFR),2,colSums(A_CNFR),"/") #Absolute matrix to relative matrix
  A_CCNp  <- sweep((A_CCN),2,colSums(A_CCN),"/") #Absolute matrix to relative matrix
  
  PVC =  (A_PVRCp) %*% as.vector(RCC)
  CMC =  (A_CMPVp) %*% as.vector(PVC)
  FRC =  (A_FRCMp) %*% as.vector((CMC))
  CNC =  (A_CNFRp) %*% as.vector((FRC))
  CC  =  (A_CCNp)  %*% as.vector((CNC))
  
  # Check routine 
  A_CRC = ((as.vector(C_DEMAND)) * A_CCN) %*% A_CNFR %*% A_FRCM %*% A_CMPV %*% A_PVRC
  EAD$RCDB = RCC / as.vector(RC) # computing the resource cost driver Benchmark
  EAD$CC = A_CRC  %*% EAD$RCDB #computing the total costs of each product
  EAD$CCB = EAD$CC / C_DEMAND # computing the unit costs of each product (customer costs)
  
  EAD$RCC = RCC
  EAD$A_CCN = A_CCN
  EAD$A_CNFR = A_CNFR
  EAD$A_FRCM = A_FRCM
  EAD$A_CMPV = A_CMPV
  EAD$A_PVRC = A_PVRC
    
  
return(EAD)}









count_nonzeros <-function(your.matrix){
  colsum_nonzeros = colSums(your.matrix != 0)
  percentageofnonzeros = sum(colsum_nonzeros)/(ncol(your.matrix)*nrow(your.matrix))
  return(percentageofnonzeros)
}



error_raiser <- function(EAD){
  # 
  # ##Matrix Size Errors if uncoupled or decoupled matrix is wanted##
  # if(EAD$NUMB_C != EAD$NUMB_CN & (EAD$DENS_CCN == 2 | EAD$TYPE_CCN == "UC"| EAD$TYPE_CCN == "DC")){
  #   stop("Number of Customers is unequal to Number of Customer Needs: Symmetrical matrix can not be generated")}
  # 
  # if(EAD$NUMB_CN != EAD$NUMB_FR & (EAD$DENS_CNFR == 2 | EAD$TYPE_CNFR == "UC"| EAD$TYPE_CNFR == "DC")){
  #   stop("Number of Customers is unequal to Number of Functional Requirements: Symmetrical matrix can not be generated")}
  # 
  # if(EAD$NUMB_FR != EAD$NUMB_CM & (EAD$DENS_FRCM == 2 | EAD$TYPE_FRCM == "UC"| EAD$TYPE_FRCM == "DC")){
  #   stop("Number of Functional Requirements is unequal to Number of Componentes: Symmetrical matrix can not be generated")}
  # 
  # if(EAD$NUMB_CM != EAD$NUMB_PV & (EAD$DENS_CMPV == 2 | EAD$TYPE_CMPV == "UC"| EAD$TYPE_CMPV == "DC")){
  #   stop("Number of Components is unequal to Number of Processes: Symmetrical matrix can not be generated")}
  # 
  # if(EAD$NUMB_PV != EAD$NUMB_RC & (EAD$DENS_PVRC == 2 | EAD$TYPE_PVRC == "UC"| EAD$TYPE_PVRC == "DC")){
  #   stop("Number of Processes is unequal to Number of Resources: Symmetrical matrix can not be generated")}
  # 
  # ##Matrix Size Errors if coupled matrix is wanted##
  # if(EAD$TYPE_CCN == "C" & EAD$DENS_CCN == 2){
  #   stop("Diagonal Customer/Customer Needs Matrix can not be generated when the Matrix Type is coupled (C)")}
  # 
  # if(EAD$TYPE_CNFR == "C" & EAD$DENS_CNFR == 2){
  #   stop("Diagonal Customer Needs/Functional Requirements Matrix can not be generated when the Matrix Type is coupled (C)")}
  # 
  # if(EAD$TYPE_FRCM == "C" & EAD$DENS_FRCM == 2){
  #   stop("Diagonal Functional Requirements/Componentes Matrix can not be generated when the Matrix Type is coupled (C)")}
  # 
  # if(EAD$TYPE_CMPV == "C" & EAD$DENS_CMPV == 2){
  #   stop("Diagonal Components/Processes Matrix can not be generated when the Matrix Type is coupled (C)")}
  # 
  # if(EAD$TYPE_PVRC == "C" & EAD$DENS_PVRC == 2){
  #   stop("Diagonal Processes/Resources Matrix can not be generated when the Matrix Type is coupled (C)")}
  # 
  #Matrix Density Errors##
  # if(EAD$TYPE_CCN == "UC" & EAD$DENS_CCN != 2){
  #   stop("Type and Density Parameters are not matching for A_CCN")}
  # 
  # if(EAD$TYPE_CNFR == "UC" & EAD$DENS_CNFR != 2){
  #   stop("Type and Density Parameters are not matching for A_CNFR")}
  # 
  # if(EAD$TYPE_FRCM == "UC" & EAD$DENS_FRCM != 2){
  #   stop("Type and Density Parameters are not matching for A_FRCM")}
  # 
  # if(EAD$TYPE_CMPV == "UC" & EAD$DENS_CMPV != 2){
  #   stop("Type and Density Parameters are not matching for A_CMPV")}
  # 
  # if(EAD$TYPE_PVRC == "UC" & EAD$DENS_PVRC != 2){
  #   stop("Type and Density Parameters are not matching for PVRC")}
  
}




  