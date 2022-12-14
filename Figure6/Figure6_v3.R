# plot Figure8 - Margot
library(ggplot2)
library("gridExtra")

dat<-read.table(file="/Users/martinkapun/Documents/GitHub/data-paper/Figure6/Figure6_data.txt",header=T,fill =T,sep="\t")

dat_PoolSNP<-dat[dat$FILE=="PoolSNP",]
dat_SNAPE<-dat[dat$FILE=="SNAPE",]

# PoolSNP plots
plot1<-ggplot(dat_PoolSNP, aes(x=Continent, y=Pi)) + geom_boxplot(, show.legend = FALSE) + labs(y = "Nucleotide diversity", tag = "A") + theme_bw() + theme(axis.title.x=element_blank()) + facet_grid(~ FILE) + scale_x_discrete(limits=c("Africa","North America","Europe")) + scale_y_continuous(labels=function(x){sprintf("%.3f", x)},limits=c(0.0037, 0.007),breaks=seq(0.004, 0.007, 0.001))  
plot2<-ggplot(dat_PoolSNP, aes(x=Continent, y=Watterson)) + geom_boxplot(, show.legend = FALSE) + labs(y = "Theta Watterson", tag = "C") + theme_bw()  + theme(axis.title.x=element_blank()) + facet_grid(~ FILE) + scale_x_discrete(limits=c("Africa","North America","Europe")) + scale_y_continuous(labels=function(x){sprintf("%.3f", x)},limits=c(0.0026, 0.0068),breaks=seq(0.003, 0.006, 0.001))  
plot3<-ggplot(dat_PoolSNP, aes(x=Continent, y=Tajima_D)) + geom_boxplot(, show.legend = FALSE) +  labs(y = "Tajima's D", tag = "B") +  theme_bw() + theme(axis.title.x=element_blank()) + facet_grid(~ FILE) + scale_x_discrete(limits=c("Africa","North America","Europe")) + scale_y_continuous(labels=function(x){sprintf("%.3f", x)},limits=c(-0.285, 1.65),breaks=seq(0, 1.5, 0.5)) 
plot4<-ggplot(dat_PoolSNP, aes(x=Continent, y=pn_ps)) + geom_boxplot(, show.legend = FALSE) + labs(y =expression('p'[N]*'/p'[S]), tag = "D") +  theme_bw() + theme(axis.title.x=element_blank()) + facet_grid(~ FILE) + scale_x_discrete(limits=c("Africa","North America","Europe")) + scale_y_continuous(labels=function(x){sprintf("%.3f", x)},limits=c(0.23, 0.53),breaks=seq(0.3, 0.5, 0.1)) 

# SNAPE plots
plot5<-ggplot(dat_SNAPE, aes(x=Continent, y=Pi)) + geom_boxplot(, show.legend = FALSE) + labs(y = "Nucleotide diversity", tag = "") + theme_bw()   + theme(axis.title.x=element_blank())+ facet_grid(~ FILE) + scale_x_discrete(limits=c("North America","Europe")) + scale_y_continuous(labels=function(x){sprintf("%.3f", x)},limits=c(0.0037, 0.007),breaks=seq(0.004, 0.007, 0.001))  
plot6<-ggplot(dat_SNAPE, aes(x=Continent, y=Watterson)) + geom_boxplot(, show.legend = FALSE) + labs(y = "Theta Watterson", tag = "") + theme_bw() + theme(axis.title.x=element_blank())   + facet_grid(~ FILE) + scale_x_discrete(limits=c("North America","Europe")) + scale_y_continuous(labels=function(x){sprintf("%.3f", x)},limits=c(0.0026, 0.0068),breaks=seq(0.003, 0.006, 0.001))
plot7<-ggplot(dat_SNAPE, aes(x=Continent, y=Tajima_D)) + geom_boxplot(, show.legend = FALSE) +  labs(y = "Tajima's D", tag = "") +  theme_bw() + theme(axis.title.x=element_blank())  + facet_grid(~ FILE) + scale_x_discrete(limits=c("North America","Europe")) + scale_y_continuous(labels=function(x){sprintf("%.3f", x)},limits=c(-0.285, 1.65),breaks=seq(0, 1.5, 0.5))  
plot8<-ggplot(dat_SNAPE, aes(x=Continent, y=pn_ps)) + geom_boxplot(, show.legend = FALSE) + labs(y =expression('p'[N]*'/p'[S]), tag = "") +  theme_bw() + theme(axis.title.x=element_blank())  + facet_grid(~ FILE) + scale_x_discrete(limits=c("North America","Europe")) + scale_y_continuous(labels=function(x){sprintf("%.3f", x)},limits=c(0.23, 0.53),breaks=seq(0.3, 0.5, 0.1)) 


pdf("/Users/martinkapun/Documents/GitHub/data-paper/Figure6/Figure6_v3.pdf",widt=12,height=6)
# make final Figure 8
grid.arrange(plot1, 
             plot5, 
             plot3, 
             plot7, 
             plot2, 
             plot6, 
             layout_matrix = rbind(c(1,2,3,4),
                                   c(1,2,5,6)))
dev.off()


        ncol=2, nrow=2, widths=c(1,0.6,1,0.6), heights=c(1, 1))
        

