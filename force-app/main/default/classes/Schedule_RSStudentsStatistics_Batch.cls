public class Schedule_RSStudentsStatistics_Batch implements Schedulable{

   public void execute(SchedulableContext sc) {
      RSStudentsStatistics_Batch b = new RSStudentsStatistics_Batch(); 
      database.executebatch(b, 500);
   }

}