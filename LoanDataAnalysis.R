#Uploading necessary packages
library(reshape)
library(moments)
library(stringr)
library(plyr)
library(Hmisc)
library(corrplot)
library(car)
require(gridExtra)

options(digits=4)

#Loading raw Data set prosperLoanData
rawcsv<-read.csv("prosperLoanData.csv", check.names=TRUE, na.strings=c("","NA"))

#Extracting 9 columns of interest and renaming them
csv<-rename(rawcsv[,c("LoanMonthsSinceOrigination",
                      "LoanOriginalAmount",
                      "LoanOriginationQuarter",
                      "LoanStatus",
                      "ProsperRating..Alpha.",
                      "ProsperScore",
                      "BorrowerRate",
                      "BorrowerState",
                      "StatedMonthlyIncome")],
                      c(
                      LoanMonthsSinceOrigination="L.Months.Since.Originated",
                      LoanOriginalAmount="L.Orig.Amount",
                      LoanOriginationQuarter="L.Orig.Quarter",
                      LoanStatus="Loan.Status",
                      ProsperRating..Alpha.="Prosper.Rating",
                      ProsperScore="Prosper.Score",
                      BorrowerRate="Borrower.Rate",
                      BorrowerState="Borrower.State",
                      StatedMonthlyIncome="Stated.Monthly.Income"))

#Central tendancy and dispersion
str(csv)
summary(csv)
#splitting L.Orig.Quarter into two seperated columns: Loan.Quarter and Loan.Creation.Year
csv<-mutate(csv,"Loan.Quarter"=str_split_fixed(csv$L.Orig.Quarter, " ", 2)[,1])
csv<-mutate(csv,"Loan.Year"=str_split_fixed(csv$L.Orig.Quarter, " ", 2)[,2])
csv[,"Loan.Quarter"]<-as.factor(csv[,"Loan.Quarter"])
csv[,"Loan.Year"]<-as.factor(csv[,"Loan.Year"])
###csv<-subset(csv,,-(L.Orig.Quarter))

#Univariate Plots Section
#L.Months.Since.Originated
#1
####boxplot(csv$L.Months.Since.Originated, horizontal = T, main="Duration of Loans (Months)",
####        xlab="Frequency")
#2
hist(csv$L.Months.Since.Originated, main="Duration of Loans (Months)", xlab="Months")
####lines(density(csv$L.Months.Since.Originated), col="blue")
skewness(csv$L.Months.Since.Originated)
kurtosis(csv$L.Months.Since.Originated)

#L.Orig.Amount
boxplot(csv$L.Orig.Amount, horizontal = T, main="Loan Original Amount", xlab="Loan Quantity")
unname(quantile(csv$L.Orig.Amount,0.25))

#Quarter & Year
table.quarter<-table(csv$Loan.Quarter)
par(mar=c(5,5,2,2), mgp=c(3.5,0.5,0))
#####barplot(table.quarter,xlab = "Quarter",ylab = "count",main = "Loan Creation Quarter")
labs<- paste("(",names(table.quarter),")", "\n", table.quarter, sep="")
pie(table.quarter, labels = labs, main = "Loan Creation Quarter")

table.year<-table(csv$Loan.Year)
barplot(table.year,xlab = "Year",ylab = "count",main = "Loan Creation Year")

#Loan status
table.status<-table(csv$Loan.Status)
par(mar=c(5,10,2,2), mgp=c(-1,0.5,0))
barplot(table.status,xlab = "count",main = "Loan Status", las=2, horiz = T)

#Prosper Rating & score
table.rating<-table(csv$Prosper.Rating)
par(mar=c(5,3,2,2), mgp=c(2,0.5,0))
barplot(table.rating,ylab = "count",xlab="Prosper Rating", main = "Prosper Rating")
table.score<-table(csv$Prosper.Score)
barplot(table.score,ylab = "count",xlab="Prosper Score", main = "Prosper Score")

##Borrower Rate, State and Stated Monthly Income
dens.rate <- density(csv$Borrower.Rate)
plot(dens.rate, main="Density of Borrower Rate", xlab = "Borrower Rate")
mean(csv$Borrower.Rate)
#state
table.state <- table(csv$Borrower.State)
par(mar=c(4,3,1,2),mgp=c(1.5,0,0))
barplot(table.state, ylab = "Borrower State", xlab="count", main = "Borrower State", 
        horiz = T, las=1, cex.names=0.5)
#Monthly Income
par(mgp=c(2,0.5,0))
hist(csv$Stated.Monthly.Income, main="Stated Monthly Income (Dollars)", 
     xlab="Monthly Income", breaks = 5000, xlim = c(0,50000))
max(csv$Stated.Monthly.Income)

#Bivariate analysis
#duplicating status column for modification
csv$Loan.Stat.mod<-csv$Loan.Status
#uniting all due statuses
csv$Loan.Stat.mod<-recode(csv$Loan.Status,"c('Past Due (>120 days)', 
                          'Past Due (1-15 days)', 
                          'Past Due (16-30 days)',
                          'Past Due (31-60 days)', 
                          'Past Due (61-90 days)', 
                          'Past Due (91-120 days)')= 'Past Due'")

csv$Loan.Stat.mod<-recode(csv$Loan.Stat.mod,"c('Defaulted',
                          'Chargedoff')='Defaulted'")
csv$Loan.Stat.mod<-recode(csv$Loan.Stat.mod,"c(                         
                          'Current',
                          'Cancelled',
                          'FinalPaymentInProgress',
                          'Completed')='Current or Completed'")

#correlation matrix

quantit<-rcorr(as.matrix(csv[,c("L.Months.Since.Originated", "L.Orig.Amount", "Prosper.Score", "Borrower.Rate", "Stated.Monthly.Income")], 
                         use = "complete.obs"))
#Function ordering correlations and p-values together
flattenCorrMatrix <- function(cormat, pmat) {
  ut <- upper.tri(cormat)
  data.frame(
    row = rownames(cormat)[row(cormat)[ut]],
    column = rownames(cormat)[col(cormat)[ut]],
    cor  =(cormat)[ut],
    p = pmat[ut]
  )
}
#Applying the function above
arrange(flattenCorrMatrix(quantit$r, quantit$P),desc(abs(cor)))
par(mar=c(1,2,4,2))
corrplot(quantit$r, type="lower", order="hclust", 
         p.mat = quantit$P, sig.level = 0.01, insig = "blank", tl.col = "black", 
         tl.srt = 45, mar=c(1,1,1,1))

#BorrowerRate~ProsperRating
qplot(csv$Borrower.Rate,fill=csv$Prosper.Rating)
#Year~Status
qplot(Loan.Year,data=csv, fill=Loan.Stat.mod)
S.Y<-table(csv$Loan.Stat.mod, csv$Loan.Year)
S.Y.p<-prop.table(S.Y,2)
S.Y.p
#Amount~BorrowerRate(ProsperScore)
qplot(L.Orig.Amount,Borrower.Rate,data=subset(csv,!is.na(Prosper.Score)), color=Prosper.Score)
#Amount~L.Months.Since.Originated (Loan.Stat.mod)
g1<-qplot(csv$L.Orig.Amount,csv$L.Months.Since.Originated,color=csv$Loan.Stat.mod, main = "Loan Amount and Duration", 
          ylab = "Loan Duration (Months)", xlab = "Loan Amount")+
  theme(legend.position="bottom")+
  scale_color_manual(values=c("darkgreen","red", "yellow"),name = "Loan Status")
  
filt1<-subset(csv$L.Orig.Amount,csv$Loan.Stat.mod!="Current or Completed")
filt2<-subset(csv$L.Months.Since.Originated,csv$Loan.Stat.mod!="Current or Completed")
filt3<-subset(csv$Loan.Stat.mod,csv$Loan.Stat.mod!="Current or Completed")
g2<-qplot(filt1,filt2,color=filt3, main = "Loan Amount and Duration", xlab = "Loan Amount", ylab = "Loan Duration (Months)")+
  scale_color_manual(values=c("red", "yellow"))+theme(legend.position="none")
grid.arrange(g1, g2, nrow=2)
#Score~Rating
R.Y<-table(csv$Prosper.Rating, csv$Prosper.Score)
R.Y.p<-prop.table(R.Y,1)
barplot(R.Y, main="Loans by Score and Rating",
        xlab="Score", col=rainbow(7), ylab = "Count",
        legend = rownames(R.Y),
        args.legend = list(x = "topright"))











####install.packages("PerformanceAnalytics")
####library("PerformanceAnalytics")
####chart.Correlation(as.matrix(csv[,c("L.Months.Since.Originated", "L.Orig.Amount", 
####                                   "Prosper.Score", "Borrower.Rate", 
####                                   "Stated.Monthly.Income")], 
####                            use = "complete.obs"), histogram=TRUE, pch=19)

#Categorical Data
#Year & Quarter
Q.year<-table(csv$Loan.Quarter, csv$Loan.Year)
barplot(Q.year, main="Loans by year and quarter",
        xlab="Year", col=rainbow(4),
        legend = rownames(Q.year),
        args.legend = list(x = "top"))
#Loan Status & Prosper rating
#duplicating status column for modification
csv$Loan.Stat.mod<-csv$Loan.Status
#uniting all due statuses
csv$Loan.Stat.mod<-recode(csv$Loan.Status,"c('Past Due (>120 days)', 
                          'Past Due (1-15 days)', 
                          'Past Due (16-30 days)',
                          'Past Due (31-60 days)', 
                          'Past Due (61-90 days)', 
                          'Past Due (91-120 days)')= 'Past Due'")
                          
csv$Loan.Stat.mod<-recode(csv$Loan.Stat.mod,"c('Defaulted',
                          'Chargedoff')='defaulted'")
csv$Loan.Stat.mod<-recode(csv$Loan.Stat.mod,"c(                         
                          'Current',
                          'Cancelled',
                          'FinalPaymentInProgress',
                          'Completed')='Current or Completed'")
#graph
par(mar=c(2,10,2,2))
L.status_P.rating<-table(csv$Prosper.Rating, csv$Loan.Stat.mod)
barplot(L.status_P.rating, main="Loan Status & Prosper rating",
        xlab="Count", col=rainbow(12),
        legend = rownames(L.status_P.rating),
        args.legend = list(x = "topright", ncol=3),
        horiz = T, las=1)

year.status<-table(csv$Loan.Stat.mod, csv$Loan.Year)
barplot(year.status, main="Loan Status & year",
        ylab="Count", col=rainbow(3),
        legend = rownames(year.status),
        args.legend = list(x = "top", ncol=1),
        horiz = F, las=1)


R.Y<-table(csv$Prosper.Rating, csv$Prosper.Score)
R.Y.p<-prop.table(R.Y,1)
barplot(R.Y, main="Loans by Score and Rating",
        xlab="Score", col=rainbow(7), ylab = "Count",
        legend = rownames(R.Y),
        args.legend = list(x = "topright"))
