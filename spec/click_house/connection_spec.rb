RSpec.describe ClickHouse::Connection do
  context 'when basic auth' do
    subject do
      ClickHouse::Connection.new(ClickHouse.config.clone.assign(
        username: 'user',
        password: 'password'
      ))
    end

    it 'works' do
      expect {  subject.tables }.to raise_error(ClickHouse::DbException, /Authentication failed/)
    end
  end

  describe 'global params' do
    subject do
      ClickHouse::Connection.new(ClickHouse.config.clone.assign(global_params: { max_threads: 3 }))
    end

    it 'sends them with a select' do
      expect(subject.select_value("SELECT getSetting('max_threads')")).to eq(3)
    end

    context 'when they name a session' do
      subject do
        ClickHouse::Connection.new(ClickHouse.config.clone.assign(global_params: { session_id: "rspec-#{SecureRandom.hex}" }))
      end

      it 'lets a select read a temporary table an execute created' do
        subject.execute('CREATE TEMPORARY TABLE session_numbers (n UInt8)')
        subject.execute('INSERT INTO session_numbers VALUES (1), (2)')

        expect(subject.select_value('SELECT count() FROM session_numbers')).to eq(2)
      end
    end
  end

  describe 'send_progress_in_http_headers' do
    it 'is sent by default' do
      expect(ClickHouse.connection.select_value("SELECT getSetting('send_progress_in_http_headers')")).to eq(true)
    end

    context 'when disabled' do
      subject do
        ClickHouse::Connection.new(ClickHouse.config.clone.assign(send_progress_in_http_headers: false))
      end

      it 'is not sent with a select' do
        expect(subject.select_value("SELECT getSetting('send_progress_in_http_headers')")).to eq(false)
      end

      it 'is not sent with a post' do
        expect(subject.compose('/', query: 'SELECT 1')).to eq('/?query=SELECT+1')
      end
    end
  end
end
