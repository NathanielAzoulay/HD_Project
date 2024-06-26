@isTest(seeAllData = false)
public class TestSchedular_MassEmail {
  public static testMethod void testschedule() {
      Test.StartTest();
      Schedular_MassEmail schedularClass = new Schedular_MassEmail();
      String sch = '0 0 1 * * ?';
      String scheduleId = system.schedule('Schedular_MassEmail class', sch, schedularClass);
      for(integer i=0;i<=5;i++){
          system.schedule('Schedular_MassEmail class'+i, sch, schedularClass);
      }
      system.schedule('Schedular_MassEmail class12', sch, schedularClass);
      system.assert(scheduleId != null);
      Test.stopTest();
  }
}