import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;


public class marketSell extends Order {

	@Override
	public void execute(Connection dbconn) {
		// TODO Auto-generated method stub
		//Do I initiate the connection here, or should that be passed?

	CallableStatement cs;
	try {
		cs = dbconn.prepareCall("{call sp_sell(?)}");

    //Input OrderID 1...always, since the SP should remove the order
    cs.setInt(1,1);
    cs.execute();
	} catch (SQLException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
}

}
